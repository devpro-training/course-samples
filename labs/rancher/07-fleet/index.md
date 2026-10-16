# Fleet

Fleet is the GitOps engine of Rancher, installed with it: a `GitRepo` names a repository, the folders to deploy, and the clusters to deploy them to, chosen by their labels.
It is the same loop as Argo CD and Flux, designed for many clusters: Fleet turns each folder into a bundle, and the agent of each cluster pulls its own.
The workspace `fleet-local` holds the cluster `local`, and `fleet-default` every other cluster.

## Labels

1. In the terminal of `docker`, label the cluster `kube` as a development cluster.
   The label goes on the management cluster, and Rancher copies it to the cluster of Fleet:

   <!-- verify: timeout=60 expect="kube   dev" -->

   ```bash exec target=docker
   CLUSTER_ID=$(kubectl --namespace fleet-default get clusters.provisioning.cattle.io kube -o jsonpath='{.status.clusterName}') && \
   kubectl label clusters.management.cattle.io "${CLUSTER_ID}" env=dev > /dev/null && \
   for i in $(seq 1 20); do [ "$(kubectl --namespace fleet-default get clusters.fleet.cattle.io kube -o jsonpath='{.metadata.labels.env}')" = dev ] && break; sleep 2; done; \
   kubectl --namespace fleet-default get clusters.fleet.cattle.io -o custom-columns=NAME:.metadata.name,ENV:.metadata.labels.env,BUNDLES:.status.display.readyBundles
   ```

## A repository

The examples of the Fleet maintainers hold a guestbook with one overlay per environment: only the Redis leader in `dev`, three frontends and two followers in `test`.
The revision is pinned to one commit, so the lab does not change when the repository does.

1. Write the `GitRepo`, and apply it:

   <!-- verify: requires=network expect="gitrepo.fleet.cattle.io/guestbook created" -->

   ```bash exec target=docker
   cd ~/lab && tee gitrepo.yaml <<EOT && kubectl apply -f gitrepo.yaml
   apiVersion: fleet.cattle.io/v1alpha1
   kind: GitRepo
   metadata:
     name: guestbook
     namespace: fleet-default
   spec:
     repo: ${FLEET_EXAMPLES_URL}
     revision: ${FLEET_EXAMPLES_REVISION}
     paths:
       - multi-cluster/manifests
     targets:
       - name: dev
         clusterSelector:
           matchLabels:
             env: dev
       - name: test
         clusterSelector:
           matchLabels:
             env: test
   EOT
   ```

2. Wait until the bundle is deployed and ready.
   Fleet clones the repository in `local`, makes one bundle per folder, named after the `GitRepo` and the path, and the agent of `kube` applies it.
   The agent of Fleet is itself a bundle:

   <!-- verify: requires=network timeout=300 expect="guestbook-multi-cluster-manifests" -->

   ```bash exec target=docker
   for i in $(seq 1 90); do kubectl --namespace fleet-default get gitrepo guestbook -o jsonpath='{.status.display.readyBundleDeployments}' | grep -q "^1/1" && break; sleep 3; done; \
   kubectl --namespace fleet-default get gitrepo guestbook -o custom-columns=NAME:.metadata.name,COMMIT:.status.commit,READY:.status.display.readyBundleDeployments && \
   kubectl --namespace fleet-default get bundles
   ```

3. In the terminal of `kube`, the namespace of the example holds the frontend and the leader only:

   <!-- verify: timeout=120 expect="redis-master" -->

   ```bash exec target=kube
   kubectl --namespace fleet-mc-manifest-example get deployments
   ```

## Another environment

1. In the terminal of `docker`, move the cluster to `test`.
   Nothing changes in Git, the target changes:

   <!-- verify: expect="cluster.management.cattle.io/c-" -->

   ```bash exec target=docker
   kubectl label clusters.management.cattle.io "$(kubectl --namespace fleet-default get clusters.provisioning.cattle.io kube -o jsonpath='{.status.clusterName}')" env=test --overwrite
   ```

2. In the terminal of `kube`, the overlay of `test` is applied: three frontends and two followers:

   <!-- verify: timeout=240 expect="redis-slave" -->

   ```bash exec target=kube
   for i in $(seq 1 80); do [ "$(kubectl --namespace fleet-mc-manifest-example get deployment frontend -o jsonpath='{.status.readyReplicas}' 2> /dev/null)" = 3 ] && break; sleep 3; done; \
   kubectl --namespace fleet-mc-manifest-example get deployments
   ```

## The interface

1. [**Continuous Delivery**, **Git Repos**](:action:ui.gitrepos) shows `guestbook`, its commit, its target and its clusters ready.
   The same page creates a `GitRepo` with a form, **Add Repository**, and **Clusters** and **Cluster Groups** set the labels that targets select.
