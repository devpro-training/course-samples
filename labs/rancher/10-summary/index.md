# Summary

What was run, what to keep, how to start, and what else exists.

---

## Cheat sheet

Task                              | Command or place
----------------------------------|---------------------------------------------------------------------------------------------------------
Install                           | `helm install rancher rancher --repo <url> --namespace cattle-system --set hostname=<name>`, cert-manager first
First password                    | `--set bootstrapPassword=...`, or the Secret `bootstrap-secret` of `cattle-system`
Server URL                        | The first page, or `kubectl patch settings.management.cattle.io server-url`
List the clusters                 | `kubectl get clusters.provisioning.cattle.io --all-namespaces`, or **Cluster Management**
Import a cluster                  | A `Cluster` with no specification in `fleet-default`, then its manifest applied in the cluster
Reach a cluster through Rancher   | A kubeconfig of **Download KubeConfig**, server `https://<rancher>/k8s/clusters/<id>`
API login                         | `POST /v3-public/localProviders/local?action=login`, then `Authorization: Bearer <token>`
A team                            | A `Project`, a `ProjectRoleTemplateBinding`, and namespaces annotated `field.cattle.io/projectId`
GitOps                            | A `GitRepo` of `fleet.cattle.io`, with targets by `clusterSelector`
Cluster API                       | `CAPIProvider`, `ClusterClass`, `Cluster`, and the label `cluster-api.cattle.io/rancher-auto-import`
Detach                            | Delete the cluster in Rancher: the agents go, the workloads stay

---

## What to remember

- **A layer, not a platform to move into**: the clusters stay standard Kubernetes clusters, and Rancher manages them from outside.
- **Everything is a resource**: clusters, users, roles, projects and settings are objects of `local`, so the interface, the API, `kubectl` and Git are four ways to the same state.
- **One door**: the authentication proxy and impersonation give a person the same identity in every cluster, and RBAC of each cluster enforces it.
- **The cluster calls Rancher**: the agent opens the tunnel, so a cluster behind a firewall or a NAT is managed with one outgoing connection.
- **The trust is one authority**: the agent checks Rancher with the checksum of its CA, so a certificate of the company or of Let's Encrypt is worth setting up first.

---

## Good practices

- **Dedicate the `local` cluster**: three nodes of RKE2 or K3s in production, nothing else on them, and the version of the support matrix.
- **A real certificate and a real name**, from the start: the name is in every agent, and changing it later means touching every cluster.
- **Back up Rancher** with Rancher Backups, and test a restore: the state of the layer is the resources of `local`.
- **An identity provider, not local users**: groups of the directory mapped to roles, and the local `admin` kept for emergencies.
- **Least privilege by project**: `project-member` for a team, `cluster-owner` for few, and the global role `user` by default.
- **Download the kubeconfigs of the authorized cluster endpoint** for provisioned clusters, so they stay reachable when Rancher is not.
- **Upgrade in order**: Rancher first, within its matrix, then the clusters, one minor version at a time.
- **Declare it**: Helm values, settings, projects and `GitRepo` in Git, the interface for exploring and for the exceptional.

---

## Getting started

Goal                   | Path
-----------------------|------------------------------------------------------------------------------------------------------------------------
Try it in minutes      | One container, `docker run -d --privileged -p 80:80 -p 443:443 rancher/rancher`, which the documentation keeps for development and tests
Learn it               | This lab: a Helm chart on k3s or k3d, and a cluster imported
Run it                 | Three nodes of RKE2 or K3s, the chart with a real certificate, Rancher Backups, an identity provider
Buy support            | SUSE Rancher Prime, from SUSE or a cloud marketplace
Have it run for you    | A managed Rancher, such as the OVHcloud Managed Rancher Service, which states a SLA of 99.9% and handles updates

- References: [quick start](https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/helm-cli),
  [requirements](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/installation-requirements),
  [support matrix](https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/).

---

## A lock-in?

What ties a team to Rancher, and what does not:

Free to leave                                                      | Tied to Rancher
-------------------------------------------------------------------|---------------------------------------------------------------------------------
Apache 2.0, the full product free to run, with no licence key      | One vendor decides the roadmap, with no foundation behind Rancher itself
Any CNCF conformant cluster imported, and detached in a minute     | RKE2 and K3s clusters it provisions are upgraded through it
Workloads keep running without Rancher, as the lab showed           | Projects, role templates and the proxy are concepts of Rancher, not of Kubernetes
Fleet deploys plain YAML, Helm and Kustomize from Git              | `fleet.yaml` and `GitRepo` are Fleet's own
Cluster API, Helm, cert-manager, upstream projects                 | A Prime subscription is SUSE's, the same code without it

- **The test of a lock-in is the exit**: an imported cluster leaves with one deletion, its namespaces of Rancher removed and everything else kept.
- **The cost of leaving is the work, not the clusters**: the roles, projects and pipelines rebuilt in the next tool.

---

## The alternatives

Product                                    | What it manages, read on its own pages (October 2026)
-------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------
Red Hat Advanced Cluster Management        | A hub on OpenShift only, sold with OpenShift Platform Plus; EKS, AKS, GKE and conformant clusters are listed and imported, not created or upgraded
Broadcom VMware, VCF                       | vSphere Kubernetes Service clusters on vSphere; Tanzu Mission Control SaaS ended on 15 November 2025, the self-managed version manages VKS and attaches conformant clusters
Azure Arc-enabled Kubernetes               | "any CNCF certified Kubernetes clusters", from a control plane in Azure, with GitOps by Flux or Argo CD
Spectro Cloud Palette, Kubermatic KKP      | Commercial platforms that provision and manage clusters on many infrastructures
Open Cluster Management                    | The upstream of Red Hat ACM, a CNCF sandbox project since 9 November 2021: placement, policies, add-ons, no interface of its own
Gardener, k0rdent                          | Open source cluster managers: Gardener under the NeoNephos Foundation, k0rdent of Mirantis under Apache 2.0
Portainer, Headlamp, Lens                  | Interfaces over clusters, with less of the lifecycle and of the access model

---

## Is there a real alternative?

- **For one platform, yes**: a company on OpenShift has ACM, a company on vSphere has VCF, a company on one cloud has its console: each manages its own platform best, and the others with less.
- **For many platforms, from one open layer, few**: the two large suites are centered on their own distribution and infrastructure, the clouds on their own account,
  and the open source projects cover parts of the list, placement, provisioning or an interface.
- **The criteria to compare**: which clusters it creates and upgrades, which it only imports, where the control plane runs, the identity and RBAC model, the GitOps engine, the licence, and what happens to the clusters when it is gone.
- **The lab is the evaluation**: the same steps, install, import, access, GitOps and detach, run against a candidate, give an answer that no slide does.

---

## Next

- **The series**: zero trust, then NeuVector, which Rancher installs from its catalog and shows in its interface, then observability.
- **Before**: k3s, k3d, Helm, Argo CD and Flux are the courses this one builds on.
- **Reference**: [Rancher documentation](https://ranchermanager.docs.rancher.com/), [Fleet](https://fleet.rancher.io/), [Rancher Turtles](https://turtles.docs.rancher.com/),
  [rancher2 Terraform provider](https://registry.terraform.io/providers/rancher/rancher2/latest/docs).
