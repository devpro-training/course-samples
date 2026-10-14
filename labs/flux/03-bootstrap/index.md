# Bootstrap

Flux is installed by a command that does two things: it applies the controllers to the cluster, and it commits their manifests to the repository, together with the object that makes Flux follow that same repository.
From then on, Flux is itself a folder of Git.

## The cluster

1. Create the cluster `hub`.
   Traefik is disabled: nothing in this lab needs it, and the cluster starts faster and uses less memory:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create hub --image "${NODE_IMAGE}" --k3s-arg "--disable=traefik@server:*"
   ```

2. Wait until the node is ready:

   <!-- verify: timeout=120 expect="ready nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "ready nodes: $(kubectl get nodes | grep -c ' Ready')"
   ```

3. Ask `flux` whether the cluster can run it.
   The command checks the version of Kubernetes and the API, and installs nothing:

   <!-- verify: timeout=60 expect="prerequisites checks passed" -->

   ```bash exec target=docker
   flux check --pre
   ```

## The repository

The repository `fleet` holds everything the clusters should be: Flux itself, the platform and the applications.
Flux needs an account that can write to it once, at the bootstrap, and read it afterwards.
A token of the account is used here instead of a password, with the one scope it needs.

1. Create the repository, with a first commit on `main`:

   <!-- verify: expect="repository: fleet" -->

   ```bash exec target=docker
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"fleet","default_branch":"main","auto_init":true}' \
     "${GITEA_BASE_URL}/api/v1/user/repos" | python3 -c 'import json,sys; print("repository:", json.load(sys.stdin)["name"])'
   ```

2. Make the token, and keep it in a file only the user reads:

   <!-- verify: expect="token length: 40" -->

   ```bash exec target=docker
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"flux","scopes":["write:repository"]}' \
     "${GITEA_BASE_URL}/api/v1/users/${GITEA_ADMIN_USER}/tokens" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha1"], end="")' > ~/lab/flux-token && \
   chmod 600 ~/lab/flux-token && \
   echo "token length: $(wc -c < ~/lab/flux-token)"
   ```

3. The cluster reaches the server as `host.k3d.internal`, and the machine does not know that name, so it is mapped to the loopback, where Gitea listens too.
   The same URL then works from a Pod and from the command line, and it is the one Flux keeps:

   <!-- verify: expect="mapped names: 1" -->

   ```bash exec target=docker
   grep -q host.k3d.internal /etc/hosts || echo "127.0.0.1 host.k3d.internal" >> /etc/hosts
   echo "mapped names: $(grep -c host.k3d.internal /etc/hosts)"
   ```

## The bootstrap

`flux bootstrap git` works with any Git server.
`--token-auth` makes it use the token over HTTP, where the default is an SSH deploy key, and `--allow-insecure-http` is needed because the lab server has no TLS.
`--path` is the folder of the repository this cluster follows.

1. Bootstrap the cluster:

   <!-- verify: requires=network timeout=240 expect="all components are healthy" -->

   ```bash exec target=docker
   flux bootstrap git --url "${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/fleet.git" --branch main --path clusters/hub \
     --token-auth --username "${GITEA_ADMIN_USER}" --password "$(cat ~/lab/flux-token)" --allow-insecure-http --silent
   ```

2. The controllers are four Deployments in the namespace `flux-system`:

   <!-- verify: expect="notification-controller" -->

   ```bash exec target=docker
   kubectl --namespace flux-system get deployments
   ```

3. And the resources Flux is told things with are definitions of the cluster:

   <!-- verify: expect="kustomizations.kustomize.toolkit.fluxcd.io" -->

   ```bash exec target=docker
   kubectl get crd | grep "toolkit.fluxcd.io" | cut -d ' ' -f 1
   ```

4. Check the whole installation:

   <!-- verify: timeout=60 expect="all checks passed" -->

   ```bash exec target=docker
   flux check
   ```

## What it committed

1. Clone the repository, and look at what the bootstrap pushed.
   The remote carries the token, so a later `git push` needs no question; the file `~/lab/flux-token` is the only place the lab keeps it:

   <!-- verify: expect="gotk-components.yaml" -->

   ```bash exec target=docker
   cd ~/lab && rm -rf fleet && \
   git clone -q "http://${GITEA_ADMIN_USER}:$(cat ~/lab/flux-token)@127.0.0.1:3000/${GITEA_ADMIN_USER}/fleet.git" && \
   cd fleet && find clusters -type f | sort
   ```

2. `gotk-sync.yaml` is the pair of objects that make Flux follow the repository: a `GitRepository` that fetches it, and a `Kustomization` that applies the folder `clusters/hub`.
   `gotk-components.yaml` is the manifest of the controllers, which the bootstrap rendered and committed:

   <!-- verify: expect="path: ./clusters/hub" -->

   ```bash exec target=docker
   cd ~/lab/fleet && cat clusters/hub/flux-system/gotk-sync.yaml
   ```

3. The two last commits are the bootstrap's, made by `Flux` after the first one of the repository:

   <!-- verify: expect="Add Flux sync manifests" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git log --format='%an: %s'
   ```

4. Flux reads it:

   <!-- verify: expect="flux-system" -->

   ```bash exec target=docker
   flux get sources git && flux get kustomizations
   ```

5. The credential Flux fetches with is a Secret of the cluster.
   Whoever reads the namespace reads the token, which is why it has the one scope that reads and writes the repository `fleet` and nothing else:

   <!-- verify: expect="password" -->

   ```bash exec target=docker
   kubectl --namespace flux-system get secret flux-system --output jsonpath='{.data}' | python3 -c 'import json,sys; print(sorted(json.load(sys.stdin)))'
   ```
