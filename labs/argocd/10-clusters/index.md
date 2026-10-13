# Two clusters

One Argo CD can deploy to many clusters.
A cluster is declared to it with a Secret of its namespace, which holds the address of the API server and a credential, and the labels of that Secret are what an ApplicationSet selects on.

## A second cluster

1. Create the cluster `staging`.
   It joins the Docker network of the hub, so that the Pods of Argo CD reach its API server by the name of its container, and the context of `kubectl` stays on the hub:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create staging --image "${NODE_IMAGE}" --network k3d-hub \
     --k3s-arg "--disable=traefik,metrics-server@server:*" --kubeconfig-switch-context=false
   ```

2. Wait until its node is ready, and list the contexts of the machine:

   <!-- verify: timeout=120 expect="staging nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl --context k3d-staging get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "staging nodes: $(kubectl --context k3d-staging get nodes | grep -c ' Ready')" && \
   kubectl config get-contexts --output name
   ```

## Register it

`argocd cluster add` does this from the command line: it creates a ServiceAccount `argocd-manager` in the cluster, and stores its token in a Secret of Argo CD.
It takes the address from the kubeconfig, which here is a port of the machine that a Pod does not reach, so the lab does the same by hand: it is also the form that Terraform produces, in the slides after this step.

1. In the staging cluster, make the identity of Argo CD, with the rights of `cluster-admin` and a token that does not expire:

   <!-- verify: expect="token: present" -->

   ```bash exec target=docker
   kubectl --context k3d-staging --namespace kube-system create serviceaccount argocd-manager > /dev/null && \
   kubectl --context k3d-staging create clusterrolebinding argocd-manager --clusterrole cluster-admin --serviceaccount kube-system:argocd-manager > /dev/null && \
   kubectl --context k3d-staging apply -f - > /dev/null <<EOT
   apiVersion: v1
   kind: Secret
   metadata:
     name: argocd-manager-token
     namespace: kube-system
     annotations:
       kubernetes.io/service-account.name: argocd-manager
   type: kubernetes.io/service-account-token
   EOT
   for i in $(seq 1 20); do [ -n "$(kubectl --context k3d-staging --namespace kube-system get secret argocd-manager-token --output jsonpath='{.data.token}')" ] && break; sleep 1; done; \
   echo "token: $([ -n "$(kubectl --context k3d-staging --namespace kube-system get secret argocd-manager-token --output jsonpath='{.data.token}')" ] && echo present)"
   ```

2. In the hub, declare the cluster: a Secret with the label `argocd.argoproj.io/secret-type: cluster`, and one label of the lab, `env`, which an ApplicationSet will select:

   <!-- verify: expect="secret/cluster-staging created" -->

   ```bash exec target=docker
   TOKEN=$(kubectl --context k3d-staging --namespace kube-system get secret argocd-manager-token --output jsonpath='{.data.token}' | base64 -d) && \
   CA=$(kubectl --context k3d-staging --namespace kube-system get secret argocd-manager-token --output jsonpath='{.data.ca\.crt}') && \
   kubectl --context k3d-hub apply -f - <<EOT
   apiVersion: v1
   kind: Secret
   metadata:
     name: cluster-staging
     namespace: argocd
     labels:
       argocd.argoproj.io/secret-type: cluster
       env: staging
   stringData:
     name: staging
     server: https://k3d-staging-server-0:6443
     config: |
       {"bearerToken": "${TOKEN}", "tlsClientConfig": {"insecure": false, "caData": "${CA}"}}
   EOT
   ```

3. Argo CD lists it:

   <!-- verify: timeout=60 expect="staging" -->

   ```bash exec target=docker
   argocd cluster list
   ```

   In the interface, [**Settings**, then **Clusters**](:action:ui.clusters) lists `in-cluster` and `staging`, with their connection status.

> [!NOTE]
> The hub now holds a credential with `cluster-admin` on the staging cluster, in a Secret of its namespace.
> Whoever reads that Secret owns the cluster, so the access to the namespace `argocd` is the access to every cluster it manages.

## One ApplicationSet, every cluster

> [!NOTE]
> The blog goes to the second cluster, and the shop does not: the shop holds a `SealedSecret`, and the second cluster has neither the controller nor a key for it.
> A cluster gets its platform before its applications, which is a second ApplicationSet of the same kind, shown in the slides of the design.

The generator of clusters makes one Application per cluster that Argo CD knows, filtered by the labels of its Secret.
The template puts the name of the cluster in the name of the Application and its address in the destination.
It joins the layers of the repository, so the root deploys it:

1. Add it to the folder `bootstrap`, and push:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   tee bootstrap/blog-clusters.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: ApplicationSet
   metadata:
     name: blog-clusters
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "1"
   spec:
     goTemplate: true
     goTemplateOptions: ["missingkey=error"]
     generators:
       - clusters:
           selector:
             matchExpressions:
               - key: env
                 operator: Exists
     template:
       metadata:
         name: 'blog-{{.name}}'
       spec:
         project: default
         source:
           repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
           targetRevision: main
           path: apps/blog
         destination:
           server: '{{.server}}'
           namespace: blog
         syncPolicy:
           automated:
             selfHeal: true
           syncOptions:
             - CreateNamespace=true
   EOT
   git add . && git commit -q -m "Deploy the blog to the clusters that have an env label" && git push 2>&1
   ```

2. Sync the root, and wait for the new Application:

   <!-- verify: timeout=180 expect="blog on clusters: 2" -->

   ```bash exec target=docker
   argocd app sync root > /dev/null; \
   for i in $(seq 1 60); do argocd app get blog-staging 2> /dev/null | grep -q "Health Status: *Healthy" && break; sleep 3; done; \
   argocd app list | cut -c 1-100; \
   echo "blog on clusters: $(argocd app list -o name | grep -c '^argocd/blog$\|^argocd/blog-staging$')"
   ```

3. The blog runs in the staging cluster, which Argo CD deployed to from the hub, and the Pods are in the other cluster:

   <!-- verify: timeout=60 expect="Running" -->

   ```bash exec target=docker
   kubectl --context k3d-staging --namespace blog get pods
   ```

   In the interface, [the **Applications** page](:action:ui.applications) lists `blog` and `blog-staging`, each with its cluster: the filter **CLUSTERS** of the left bar narrows the list to one of them.

## What it costs

- **One failure domain**: the hub is the place where every cluster is configured from, so it is backed up and kept as available as what it manages.
- **A pull that goes out**: the hub opens connections to the API servers of the clusters.
  Clusters behind a firewall, or many, are what the project `argocd-agent` of `argoproj-labs` is for: agents on the clusters connect to a central control plane, and the application controllers run where the workloads are.
  Its documentation says it "is in active development with a stable core architecture".
