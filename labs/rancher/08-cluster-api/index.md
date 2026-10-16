# Cluster API

[Cluster API](https://cluster-api.sigs.k8s.io/) (CAPI) is a project of Kubernetes SIG Cluster Lifecycle: clusters described as Kubernetes resources (`Cluster`, `MachineDeployment`, `Machine`), and reconciled by providers.
An infrastructure provider makes the machines (AWS, Azure, GCP, vSphere, Docker), a bootstrap and a control plane provider make them a cluster (kubeadm, RKE2).
Rancher uses it in two ways: its own provisioning of RKE2 and K3s is built on it, and Rancher Turtles brings any CAPI provider in, and imports what it creates.

![Rancher Turtles installs Cluster API providers with CAPIProvider resources, the providers create clusters from Cluster resources, and Turtles installs the Rancher agent in each new cluster, which then registers in Rancher](../assets/rancher-capi-dark.svg#gh-dark-mode-only)
![Rancher Turtles installs Cluster API providers with CAPIProvider resources, the providers create clusters from Cluster resources, and Turtles installs the Rancher agent in each new cluster, which then registers in Rancher](../assets/rancher-capi.svg#gh-light-mode-only)

## What Rancher installed

1. Rancher v2.15 installs Turtles and the core of Cluster API by itself.
   A provider is a `CAPIProvider` resource, which the operator of Turtles installs and upgrades: only the core is there:

   <!-- verify: expect="capi-controller-manager" -->

   ```bash exec target=docker
   kubectl get capiproviders --all-namespaces && \
   kubectl get deployments --namespace cattle-capi-system && \
   kubectl get deployments --namespace cattle-turtles-system
   ```

2. The resources of Cluster API are there, with the version of their API:

   <!-- verify: expect="machinedeployments.cluster.x-k8s.io" -->

   ```bash exec target=docker
   kubectl get crd -o custom-columns=NAME:.metadata.name,VERSION:.spec.versions[-1:].name | grep -E "^NAME|\.cluster\.x-k8s\.io "
   ```

3. Rancher's own providers are the groups `rke.cattle.io` (bootstrap, control plane, cluster) and `rke-machine.cattle.io`, one machine template per node driver:

   <!-- verify: expect="rkecontrolplanes" -->

   ```bash exec target=docker
   kubectl get crd -o name | grep -E "\.rke\.cattle\.io$" | cut -d / -f 2 && \
   kubectl get crd -o name | grep -E "machinetemplates\.rke-machine\.cattle\.io$" | cut -d / -f 2 | cut -d . -f 1
   ```

4. An imported cluster is not a Cluster API cluster: Rancher manages it, and its lifecycle stays where it was created.
   Only a cluster that Rancher or a CAPI provider creates has a `Cluster` of `cluster.x-k8s.io`:

   <!-- verify: expect="No resources found" -->

   ```bash exec target=docker
   kubectl get clusters.cluster.x-k8s.io --all-namespaces
   ```

## The path to a CAPI cluster

This lab stops here, since a provider needs a cloud account or a hypervisor.
The path of the Turtles documentation is four resources, all in Git if wanted:

1. A `CAPIProvider` per provider, for example `type: infrastructure` named `aws`, with a Secret of credentials, and the RKE2 bootstrap and control plane providers.
2. A `ClusterClass`, the template of a cluster for that provider, for which the repository of Turtles holds examples (`examples/clusterclasses`).
3. A `Cluster` that refers to the class, with its version, its number of control plane and worker machines.
4. The label `cluster-api.cattle.io/rancher-auto-import: "true"` on the namespace or on the `Cluster`: Turtles then installs the agent of Rancher in the new cluster, which appears in **Cluster Management** as any other.

The certified providers, read on the documentation of Turtles: CAPRKE2 and kubeadm for bootstrap and control plane, CAPA (AWS), CAPZ (Azure), CAPV (vSphere), CAPG (GKE only), and CAPD (Docker), for development only.

## The interface

1. [**Cluster Management**, **Create**](:action:ui.create) lists what Rancher provisions itself: the hosted services (Amazon EKS, Azure AKS, Google GKE),
   RKE2 or K3s on machines of a node driver (Amazon EC2, Azure, DigitalOcean, Harvester, Linode, VMware vSphere), and **Custom**, on machines that run a registration command.
