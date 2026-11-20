# Use a chart from a catalog

A chart is an application packaged for Kubernetes, with the settings it lets the user change.
Most cloud native projects publish one, so installing a tool starts with a command and not with a folder of YAML files.
This step installs one, changes it, undoes the change, and looks at what Helm keeps.

The routine is the same for every chart of every project, four commands:

Command                          | What it does
---------------------------------|----------------------------------------------
`helm repo add <name> <url>`     | Registers a catalog
`helm search repo <word>`        | Finds a chart and its versions
`helm install <release> <chart>` | Installs it, with the values the user changes
`helm upgrade <release> <chart>` | Applies a new version or new values

## The cluster

1. Create a cluster, and wait until the node is ready.
   Traefik is disabled: nothing in this lab needs it, and the cluster starts faster:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create helm --image "${NODE_IMAGE}" --k3s-arg "--disable=traefik@server:*"
   ```

2. Wait until the node is ready:

   <!-- verify: timeout=120 expect="ready nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "ready nodes: $(kubectl get nodes | grep -c ' Ready')"
   ```

## A catalog

A chart repository is a web server with an `index.yaml` that lists charts and where to download them.
[Artifact Hub](https://artifacthub.io/) is the search engine of all the public ones, the application store of cloud native.

1. Add the repository of podinfo, a small web application made to demonstrate Kubernetes:

   <!-- verify: requires=network timeout=60 expect="has been added" -->

   ```bash exec target=docker
   helm repo add podinfo "${PODINFO_REPO}"
   ```

2. Search the repository.
   Every release of the chart is listed, the chart version first, then the version of the application it installs:

   <!-- verify: expect="podinfo/podinfo" -->

   ```bash exec target=docker
   helm search repo podinfo --versions | head -4
   ```

3. Read what the chart lets a user change, its default values.
   This is the whole interface of the chart:

   <!-- verify: requires=network timeout=60 expect="replicaCount: 1" -->

   ```bash exec target=docker
   helm show values podinfo/podinfo --version "${PODINFO_CHART_VERSION}" | head -20
   ```

## Read before installing

A chart is more than an image: it is a recipe, an installation procedure that Helm runs with the rights of the person who types the command.
It can create roles and bindings, run Jobs before or after the install (hooks), and change the cluster beyond its own namespace.
So a chart is read, as a script would be, before it is trusted.

1. Render it without installing, and count what it would create.
   `helm template` needs no cluster:

   <!-- verify: requires=network timeout=60 expect="Deployment" -->

   ```bash exec target=docker
   echo "kinds:" && \
   helm template web podinfo/podinfo --version "${PODINFO_CHART_VERSION}" | grep '^kind:' | sort | uniq -c
   ```

2. Download the chart and look for the hooks, the templates that are not part of the release but run when Helm says so, and for the roles it would create:

   <!-- verify: requires=network timeout=60 expect="roles: 0" -->

   ```bash exec target=docker
   mkdir -p ~/lab/pulled && cd ~/lab/pulled && \
   helm pull podinfo/podinfo --version "${PODINFO_CHART_VERSION}" --untar && \
   echo "hook files:" && grep -rl 'helm.sh/hook' podinfo/templates && \
   echo "roles: $(grep -rl -E 'kind: (Cluster)?Role' podinfo/templates | wc -l)"
   ```

## Install

A **release** is one installation of a chart in a cluster, with a name chosen by the user.
The same chart can be installed many times, each with its own name.

1. Install the chart as the release `web`.
   `--wait` makes Helm return when the Pods are ready:

   <!-- verify: requires=network timeout=240 expect="STATUS: deployed" -->

   ```bash exec target=docker
   helm install web podinfo/podinfo --version "${PODINFO_CHART_VERSION}" --namespace demo --create-namespace --wait --timeout 3m
   ```

2. List the releases, and see what they created.
   Helm labels everything it creates, so the Pods of the release are found with `app.kubernetes.io/instance`:

   <!-- verify: expect="REVISION" -->

   ```bash exec target=docker
   helm list --namespace demo && \
   kubectl get deployment,service,pod --namespace demo --selector app.kubernetes.io/instance=web
   ```

3. Call the application.
   `port-forward` is stopped right after the request:

   ```bash exec target=docker
   nohup kubectl port-forward --namespace demo service/web-podinfo 9898:9898 > /dev/null 2>&1 &
   ```

   <!-- verify: timeout=60 expect="greetings from podinfo" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do wget -qO- http://127.0.0.1:9898/ | grep message && break; sleep 1; done; \
   pkill -f "^kubectl port-forward"
   ```

## Change the configuration

1. Upgrade the release with a different message.
   `--set` overrides one value of the chart, and the revision of the release goes from 1 to 2:

   <!-- verify: timeout=240 expect="REVISION: 2" -->

   ```bash exec target=docker
   helm upgrade web podinfo/podinfo --version "${PODINFO_CHART_VERSION}" --namespace demo --set ui.message="Hello from Helm" --wait --timeout 3m
   ```

2. Call the application again.
   The Pod was replaced, so the forward is started again:

   ```bash exec target=docker
   nohup kubectl port-forward --namespace demo service/web-podinfo 9898:9898 > /dev/null 2>&1 &
   ```

   <!-- verify: timeout=60 expect="Hello from Helm" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do wget -qO- http://127.0.0.1:9898/ | grep message && break; sleep 1; done; \
   pkill -f "^kubectl port-forward"
   ```

3. The history lists every revision, with the chart and the application version of each:

   <!-- verify: expect="superseded" -->

   ```bash exec target=docker
   helm history web --namespace demo
   ```

## Roll back

1. Go back to the first revision.
   A rollback is a new revision, number 3, with the content of revision 1:

   <!-- verify: timeout=240 expect="Rollback was a success" -->

   ```bash exec target=docker
   helm rollback web 1 --namespace demo --wait --timeout 3m && \
   helm history web --namespace demo
   ```

2. The values given with `--set` are gone from the release, since revision 1 had none:

   <!-- verify: expect="null" -->

   ```bash exec target=docker
   helm get values web --namespace demo
   ```

## What Helm keeps

A release is not a custom resource of the cluster: Helm stores it in a Secret of the namespace, one per revision, which holds the chart, the values and the manifest.
This is why Helm needs no server, and why it can undo a change.

1. List the Secrets of the releases:

   <!-- verify: expect="sh.helm.release.v1.web.v3" -->

   ```bash exec target=docker
   kubectl get secret --namespace demo --selector owner=helm
   ```

2. Read the YAML that was sent to the cluster, the result of the templates:

   <!-- verify: expect="1 kind: Deployment" -->

   ```bash exec target=docker
   helm get manifest web --namespace demo | grep -E '^kind:' | sort | uniq -c
   helm get manifest web --namespace demo | grep -B2 -A12 '^kind: Deployment' | head -30
   ```

## Remove

1. Uninstall the release.
   Everything the release created is deleted, and nothing else:

   <!-- verify: expect="uninstalled" -->

   ```bash exec target=docker
   helm uninstall web --namespace demo && \
   echo "objects left: $(kubectl get deployment,service --namespace demo --no-headers 2> /dev/null | wc -l)"
   ```
