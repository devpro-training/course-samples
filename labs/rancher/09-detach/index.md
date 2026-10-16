# Detach

A management layer is only worth adopting if it can be left.
The page [Rancher is No Longer Needed](https://ranchermanager.docs.rancher.com/faq/rancher-is-no-longer-needed) of the documentation answers the question, and this step checks its answer for an imported cluster.

## Delete the cluster from Rancher

1. In the terminal of `docker`, delete the cluster `kube` from Rancher, as **⋮ > Delete** does in **Cluster Management**:

   <!-- verify: expect="deleted" -->

   ```bash exec target=docker
   kubectl --namespace fleet-default delete clusters.provisioning.cattle.io kube --wait=false
   ```

2. In the terminal of `kube`, Rancher removes its agents and their namespaces, in a minute or two:

   <!-- verify: timeout=240 expect="namespaces of Rancher left: 0" -->

   ```bash exec target=kube
   for i in $(seq 1 75); do kubectl get namespaces --no-headers | grep -qE "^cattle-" || break; sleep 3; done; \
   echo "namespaces of Rancher left: $(kubectl get namespaces --no-headers | grep -cE '^cattle-')"; \
   kubectl get namespaces
   ```

3. The workloads are untouched, the ones Fleet deployed and the one of the team, and the cluster answers with its own kubeconfig, as before Rancher:

   <!-- verify: expect="redis-slave" -->

   ```bash exec target=kube
   kubectl get deployments --namespace fleet-mc-manifest-example && \
   kubectl get deployments --namespace shop
   ```

4. In the terminal of `docker`, Rancher knows only `local` again:

   <!-- verify: timeout=120 expect="local" -->

   ```bash exec target=docker
   for i in $(seq 1 40); do [ "$(kubectl get clusters.management.cattle.io --no-headers | wc -l)" = 1 ] && break; sleep 3; done; \
   kubectl get clusters.management.cattle.io
   ```

## The other cases

What the documentation states for each kind of cluster, if Rancher itself is deleted:

Cluster                    | Without Rancher
---------------------------|------------------------------------------------------------------------------------------------------------------
Imported                   | Unaffected, reached as before it was registered
Hosted (EKS, AKS, GKE)     | Managed with the credentials of the cloud provider, and there is no detach of the Rancher components yet
Provisioned (RKE2 and K3s) | Reached with the authorized cluster endpoint, if it was enabled and its kubeconfig downloaded before

- The workloads of every downstream cluster "will continue to function as normal".
- Rancher itself is removed with the [Rancher Cleanup](https://github.com/rancher/rancher-cleanup) tool, and its definitions and namespaces by hand.

## The interface

1. [**Cluster Management**](:action:ui.clusters) lists `local` only.
