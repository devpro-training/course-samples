# The management layer

Rancher keeps everything it knows as Kubernetes resources of its `local` cluster: clusters, users, roles, projects, settings.
The interface, the API and `kubectl` are three views of the same objects, which is also what makes Rancher scriptable and GitOps-able.

## Rancher's own resources

1. Count the custom resource definitions by API group.
   `management.cattle.io` is Rancher itself, `provisioning.cattle.io` and `rke.cattle.io` provision clusters, `fleet.cattle.io` is Fleet, `cluster.x-k8s.io` is Cluster API:

   <!-- verify: expect="management.cattle.io" -->

   ```bash exec target=docker
   kubectl get crd -o jsonpath='{range .items[*]}{.spec.group}{"\n"}{end}' | grep -E "cattle|x-k8s" | sort | uniq -c | sort -rn
   ```

2. A cluster is two resources: a provisioning `Cluster` in a Fleet workspace (`fleet-local` for `local`, `fleet-default` for the others), and a management cluster named by an identifier:

   <!-- verify: expect="local-kubeconfig" -->

   ```bash exec target=docker
   kubectl get clusters.provisioning.cattle.io --all-namespaces && \
   kubectl get clusters.management.cattle.io
   ```

3. Each cluster also has a namespace of its own in `local`, with its projects.
   A project groups namespaces under one set of members, quotas and policies, which Kubernetes itself does not have.
   `local` comes with two, **System** and **Default**:

   <!-- verify: expect="System" -->

   ```bash exec target=docker
   kubectl --namespace local get projects.management.cattle.io -o custom-columns=NAME:.metadata.name,DISPLAY:.spec.displayName
   ```

4. Roles are defined once, at three levels: global roles for Rancher itself, and role templates for a cluster or a project, which Rancher turns into the RBAC of each cluster:

   <!-- verify: expect="project" -->

   ```bash exec target=docker
   kubectl get globalroles.management.cattle.io -o custom-columns=NAME:.metadata.name,DISPLAY:.displayName && \
   kubectl get roletemplates.management.cattle.io -o custom-columns=CONTEXT:.context --no-headers | sort | uniq -c
   ```

5. Settings and features are resources too, which is how an installation is configured without the interface:

   <!-- verify: expect="multi-cluster-management" -->

   ```bash exec target=docker
   kubectl get features.management.cattle.io | grep -E "^NAME|fleet|multi-cluster|rke2|turtles|uiextension"
   ```

## The interface

1. [The home page](:action:ui.home) lists the clusters, with their provider, distribution and version.
   The left bar is the map of Rancher: one icon per cluster, then **Cluster Management**, **Continuous Delivery** (Fleet), **Virtualization Management** (Harvester), **Users & Authentication**, **Extensions** and **Global Settings**.

2. [Explore `local`](:action:ui.local): the **Cluster Dashboard** counts the resources, nodes and deployments, and checks the control plane.
   The menu on the left is a Kubernetes explorer for every cluster: **Workloads**, **Apps**, **Service Discovery**, **Storage**, **Policy**, **More Resources**.

3. [Open a **Kubectl Shell**](:action:ui.shell): a Pod in the cluster, with `kubectl` and the rights of the person signed in, and nothing to install on a workstation.
   It shows **Connecting...** while its Pod starts, then a prompt: type `kubectl get nodes` in it.

4. [**Apps**, then **Charts**](:action:ui.charts) is the catalog: three repositories (Rancher, Partners and RKE2), from which a chart is installed in a cluster with a form.
   The Rancher repository holds the integrations of the slides, among them Longhorn, NeuVector, Rancher Backups, Rancher Compliance, Logging, Elemental and Rancher Turtles.

5. [**Extensions**](:action:ui.extensions) adds pages to the interface itself, each packaged as a Helm chart.
   The page is empty until **Add repositories** enables the repository of the partners (CloudCasa, Epinio, Nutanix among others), and a company can publish its own.
