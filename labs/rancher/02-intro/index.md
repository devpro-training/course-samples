# Rancher

The management layer of Kubernetes: one place for every cluster, every team and every distribution.

---

## The problem

- **Clusters multiply**: one per environment, region, team, customer or edge site, and a company soon runs tens or hundreds.
- **Distributions differ**: EKS, AKS, GKE, OpenShift, RKE2, K3s, kubeadm, each with its own console, access and upgrade procedure.
- **Without a layer**: one kubeconfig and one RBAC per cluster, add-ons installed by hand, versions that drift, and no inventory.
- **What a platform team needs**: one sign-in, one place to give and take access, one way to install, upgrade and observe, one view of what runs where.

---

## What Rancher is

- **A Kubernetes management tool**: the documentation says it is "to deploy and run clusters anywhere and on any provider".

- **Three ways to get a cluster**: provision one with a hosted provider (EKS, AKS, GKE), install RKE2 or K3s on machines it creates or is given, or import any existing cluster.

- **What it adds on top**, from the same page: authentication and RBAC centralized for all clusters, monitoring and alerting, logs shipped out, an application catalog of Helm charts, and Fleet for GitOps.

- **What it is not**: not a distribution (RKE2 and K3s are), not in the path of the traffic of the workloads, and not needed for a cluster to keep running.

- Reference: [What is Rancher?](https://ranchermanager.docs.rancher.com/)

---

## How it works

![Rancher runs in the local cluster with its API and interface, the authentication proxy, the cluster controllers, Fleet and Turtles; people reach it with a browser, kubectl or the API; each downstream cluster, imported, provisioned or hosted, runs a cluster agent that opens a tunnel to Rancher](../assets/rancher-dark.svg#gh-dark-mode-only)
![Rancher runs in the local cluster with its API and interface, the authentication proxy, the cluster controllers, Fleet and Turtles; people reach it with a browser, kubectl or the API; each downstream cluster, imported, provisioned or hosted, runs a cluster agent that opens a tunnel to Rancher](../assets/rancher.svg#gh-light-mode-only)

---

## The parts

Part                         | What it does, from the documentation
-----------------------------|---------------------------------------------------------------------------------------------------------------
Rancher server               | The API, the interface and the controllers, in the `local` cluster, which should be dedicated to it
Authentication proxy         | Authenticates every call, then forwards it to the cluster "with the proper Kubernetes impersonation headers"
Cluster controller           | One per downstream cluster: watches it, brings it to the desired state, writes its access policies
`cattle-cluster-agent`       | One per downstream cluster: "opens a tunnel to the corresponding cluster controller"
`rancher-system-agent`       | On each node of an RKE2 or K3s cluster of Rancher: upgrades, etcd snapshots, the fallback tunnel
Authorized cluster endpoint  | A direct kubeconfig to an RKE2 or K3s cluster, for when Rancher is down or far away
Fleet, Turtles, the webhook  | GitOps, Cluster API, and the admission checks of Rancher's own resources

- **The tunnel starts from the cluster**: a downstream cluster needs to reach Rancher, and Rancher does not need to reach it.
- Reference: [communicating with downstream clusters](https://ranchermanager.docs.rancher.com/reference-guides/rancher-manager-architecture/communicating-with-downstream-user-clusters).

---

## Capabilities

Area               | What Rancher gives                                                                        | In the lab
-------------------|-------------------------------------------------------------------------------------------|----------------------------
Inventory          | Every cluster, its provider, distribution, version and health, in one list                | Install, a second cluster
Lifecycle          | Provision RKE2 and K3s, hosted EKS, AKS, GKE, upgrades, etcd snapshots, Cluster API        | Slides, Cluster API
Access             | One sign-in (LDAP, OIDC, SAML, GitHub), global, cluster and project roles, one proxy      | Access, users and projects
Multi-tenancy      | Projects: namespaces grouped with members, quotas and policies                           | Access, users and projects
Applications       | A catalog of Helm charts per cluster, and extensions of the interface                     | The management layer
GitOps             | Fleet, built in, a `GitRepo` deployed to clusters chosen by label                        | Fleet
Operations         | Monitoring, logging, backups of Rancher, compliance scans, a shell in the browser          | The management layer
Automation         | A REST API, every object a Kubernetes resource, a Terraform provider (`rancher2`)          | Every step

---

## Integrations

Integration                     | What it is
--------------------------------|------------------------------------------------------------------------------------------------
RKE2, K3s                       | The distributions of the project: RKE2 for hardened data centers, K3s for edge and small sites
Longhorn                        | Distributed block storage, a CNCF incubating project since 4 November 2021
NeuVector                       | Container security, at runtime and in the pipeline, the subject of a next course
Harvester                       | Hyperconverged infrastructure on Kubernetes, virtual machines included, in **Virtualization Management**
Kubewarden                      | Admission policies as WebAssembly, a CNCF sandbox project since 17 June 2022
Elemental                       | The operating system of edge nodes, managed from Rancher
Fleet, Turtles                  | GitOps, and Cluster API with its providers (AWS, Azure, GCP, vSphere)
Monitoring, logging, backups    | Charts of the Rancher repository: Prometheus and Grafana, the Logging operator, Rancher Backups
Cloud and identity              | EKS, AKS and GKE through cloud credentials, Active Directory, Entra ID, Keycloak, any OIDC or SAML

- Reference: [integrations](https://ranchermanager.docs.rancher.com/integrations-in-rancher).

---

## The project

- **History**: Rancher Labs was founded in 2014, Rancher 1.0 was released on 29 March 2016 with its own orchestrator, and 2.0, on 2 May 2018, is built on Kubernetes.
  SUSE completed the acquisition of Rancher Labs on 1 December 2020.

- **Licence**: Apache 2.0, the code on [github.com/rancher/rancher](https://github.com/rancher/rancher), about 26,000 stars, written in Go.

- **Governance**: a project of one vendor, SUSE, not of a foundation: no governance file in the repository, contributions through pull requests under its `CONTRIBUTING.md`.
  K3s (CNCF sandbox since 19 August 2020), Longhorn and Kubewarden, from the same family, were given to the CNCF.

- **SUSE**: a company owned by the investment fund EQT, delisted from the Frankfurt Stock Exchange after a vote of 13 November 2023 (secondary sources).

- **Releases**: a minor version about every four months (v2.13, v2.14 and v2.15 reached Prime in December 2025, April 2026 and August 2026), and the patches of the supported lines together:
  v2.15.2, v2.14.6 and v2.13.10 on 23 September 2026.
  v2.15.0 was tagged on GitHub on 30 July 2026, a month before its Prime release, and the lab runs v2.15.2.

---

## Community and Prime

Edition                | What it is
-----------------------|-------------------------------------------------------------------------------------------------------------
Rancher (community)    | "Completely open source multi-cluster management": the same code, free, supported by the community
SUSE Rancher Prime     | A subscription: 24x7 support, a lifecycle with dates, curated applications, and add-ons such as an AI agent
Managed Rancher        | Rancher run by a provider: for example the [OVHcloud Managed Rancher Service](https://www.ovhcloud.com/en/public-cloud/managed-rancher-service/)

- **Prime lifecycle**, from SUSE: v2.15 is supported from 27 August 2026, maintained until 27 February 2027, and reaches its end of life on 27 February 2028.
- **The lab runs the community edition**, which has the capabilities of the previous slides.
- References: [SUSE Rancher](https://www.suse.com/products/rancher/), [lifecycle](https://www.suse.com/lifecycle/).

---

## In this lab

Step                  | What it shows
----------------------|---------------------------------------------------------------------------------------------------------------
Setup                 | Docker Engine, k3d, kubectl and Helm in a machine, from checked binaries
Install               | cert-manager, the chart of Rancher read then installed, its certificate, the server URL, the first login
The management layer  | Rancher's own resources, the interface, a shell in the browser, the catalog and extensions
A second cluster      | k3s in another machine, declared in Rancher, registered with one manifest, through an outgoing tunnel
Access                | The authentication proxy and impersonation, a user, a project and its role, checked by the cluster
Fleet                 | A `GitRepo` pinned to a commit, a cluster chosen by label, another environment by another label
Cluster API           | What Rancher installs for it, its own providers, and the path to a CAPI cluster
Detach                | The cluster removed from Rancher, still running, its workloads untouched

> Two virtual machines and no account: Rancher in a k3d cluster of `docker`, and k3s in `kube`.
