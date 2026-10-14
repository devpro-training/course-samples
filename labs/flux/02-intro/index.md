# Flux

A set of Kubernetes controllers that keep a cluster equal to a Git repository, with no UI, no API server and no database of its own.

---

## What it is

- **The GitOps Toolkit**: Flux is made of controllers, each with its own resources, and the controllers are the only parts.
  There is no server to reach, so a cluster that runs Flux needs no inbound access.

- **It pulls**: the controllers fetch a source (Git, Helm, OCI, a bucket), build what it holds and apply it, again at each interval.
  What is applied is compared with the cluster, and the drift is corrected.

- **Everything is a resource**: Flux is told things with objects of the namespace `flux-system`, so Flux itself can be kept in Git.

- **Its own installation is in Git**: `flux bootstrap` commits the manifests of the controllers and the object that makes them follow that same folder.

- Reference: [Flux documentation](https://fluxcd.io/flux/).

---

## How it works

![The source controller pulls a Git repository, a Helm repository or an OCI artifact, the kustomize and Helm controllers apply what it holds to the cluster, the notification controller sends events out and takes webhooks in, and image automation commits new tags to Git](../assets/flux-dark.svg#gh-dark-mode-only)
![The source controller pulls a Git repository, a Helm repository or an OCI artifact, the kustomize and Helm controllers apply what it holds to the cluster, the notification controller sends events out and takes webhooks in, and image automation commits new tags to Git](../assets/flux.svg#gh-light-mode-only)

---

## The controllers

Controller                | Resources                                                 | What it does, from the documentation
--------------------------|-----------------------------------------------------------|------------------------------------------------------------------
Source                    | `GitRepository`, `OCIRepository`, `HelmRepository`, `HelmChart`, `Bucket` | Fetches and manages the sources
Kustomize                 | `Kustomization`                                           | Reconciles the objects a source holds, with Kustomize, SOPS and health checks
Helm                      | `HelmRelease`                                             | Reconciles Helm releases
Notification              | `Provider`, `Alert`, `Receiver`                           | Events out to chat and Git, webhooks in to trigger a reconciliation
Image reflector and automation | `ImageRepository`, `ImagePolicy`, `ImageUpdateAutomation` | Scan a registry, pick a tag, and commit it to Git

- The first four are installed by default, and the image controllers are added with `--components-extra`.
- Two objects share the name `Kustomization`: the file of Kustomize in a folder, and the object of Flux in the cluster. Their `apiVersion` tells them apart.

---

## Kustomize, Kustomization and Helm

Name                          | What it is                                                                  | In the lab
------------------------------|-----------------------------------------------------------------------------|---------------------------
Kustomize                     | The Kubernetes tool that patches plain YAML, with a `kustomization.yaml`; `kubectl apply -k` runs it too | The `kustomization.yaml` of `apps/shop`
`Kustomization` of Flux       | A resource of Flux that builds a folder (with Kustomize), applies it, waits, prunes and corrects drift | `shop`, `infra`, `team-a`
Helm                          | The package manager: charts with templates and values                       | The chart `podinfo`
`HelmRelease` of Flux         | A resource of Flux that installs a chart with the Helm library, and upgrades it | `podinfo`

- **Kustomize and Helm are two ways to produce manifests**: one patches YAML, the other renders templates, and Flux runs either one.
- **Helm is the first choice for software someone else packages**: a version of a chart, a file of values, and the release history Helm keeps.
  Kustomize is for the manifests a team writes itself, and for what differs between clusters.
  Either way, a `Kustomization` of Flux delivers the files.
- **A `Kustomization` of Flux does not need Kustomize files**: with no `kustomization.yaml` in the folder, Flux builds one that lists the manifests, as in the folder `clusters/hub`.
- **The same Flux `Kustomization` can also patch inline**, with `spec.patches`, which the lab uses for the staging cluster.

---

## Who maintains it

- **A CNCF project**: accepted on 15 July 2019, incubating on 12 March 2021, graduated on 30 November 2022 (CNCF page).

- **Its origin**: Weaveworks created Flux, and the repository `fluxcd/flux2` dates from 24 April 2020.
  The first Flux, now called v1, is archived, and Flux v2 reached 2.0.0 on 5 July 2023.

- **The company behind it closed**: Weaveworks announced on 5 February 2024 that it was shutting its doors, and its CEO said the open source would continue.
  The project did not depend on it by then: the maintainers come from several organizations.

- **Who maintains it today**: `CORE-MAINTAINERS` of `fluxcd/community`, read on 14 October 2026, lists 9 people.
  ControlPlane has 3, three are independent, and NexHealth, Associmates and SUSE have one each.

- **Releases**: at least as often as Kubernetes, about two weeks after each Kubernetes minor version, and the three latest minor versions are maintained.
  The lab uses v2.9.6, published on 1 October 2026.

---

## Governance

- **Core maintainers decide**, and the same people maintain the other repositories of the `fluxcd` organization (`MAINTAINERS` of `flux2`).
- **Users come from the community**: the project asks organizations to list themselves on its adopters page, which the lab does not repeat.
- **Support is best effort**: critical fixes may be backported to the three maintained minor versions, by the community.

---

## Strengths

- **Small and composable**: controllers and resources only, no server to secure, and the optional parts are not installed.
- **Secrets are decrypted by Flux itself**, with SOPS and age, a cloud KMS or Vault, "without the need of additional controllers".
- **Tenants use the rights of their account**: a `Kustomization` or a `HelmRelease` names a ServiceAccount, and the API server of Kubernetes refuses the rest.
- **Order and health**: `dependsOn` and `wait` make a layer wait for the one below, and say why it does not move.
- **Helm and Kustomize without a command**: the Helm controller runs the library, and a `Kustomization` can patch inline.
- **Bootstrap is Git**, and so is the upgrade of Flux itself: Terraform needs one resource for it.

---

## Weaknesses

- **No UI in the project**: the ecosystem has several (the Flux Operator, Headlamp, Capacitor, Freelens, Backstage), and each is one more thing to run.
- **No view of many clusters**: each cluster has its own Flux and its own state, and a team that wants one screen adds a tool.
- **Many resources to learn**: sources, Kustomizations, releases, providers, alerts, and the `flux` command to read them.
- **It polls**: the interval is one minute at least, and a `Receiver` webhook or `flux reconcile` makes it faster.
- **Drift of a Helm release is not corrected by default**: `driftDetection` is a setting of the release, as the lab shows.
- **A secret still needs a decision**: SOPS keys, their rotation, and who holds the private key are the team's to design.
- **Bootstrap writes to the repository**: the account needs write access once, and its token stays in the cluster.

---

## Flux and Argo CD

Topic            | Flux                                              | Argo CD
-----------------|---------------------------------------------------|---------------------------------------------------
Shape            | Controllers and resources, nothing else            | Controllers, an API server, a repository server and a UI
Interface        | The `flux` command and `kubectl`, a UI from the ecosystem | A web UI, an API and a command line
Unit of work     | `Kustomization`, `HelmRelease`                     | `Application`, `ApplicationSet`
Access control   | The account named by the object, and Kubernetes RBAC | `AppProject`, accounts and RBAC of its own
Secrets          | SOPS in the controller, operators as an option     | Plugins and operators, as in the Argo CD course
Clusters         | One Flux per cluster, or `spec.kubeConfig`          | One Argo CD that registers clusters
Both             | CNCF graduated, pull model, Git as the source of truth |

- The choice is often about the interface the team wants, and who runs the platform.
- Both can run in the same organization, one per team or per cluster.

---

## What the lab covers

1. **Bootstrap** a k3d cluster with Gitea, and read what was committed.
2. **Helm**: a `HelmRepository`, a `HelmRelease`, a change of values, and the drift of a release.
3. **A `Kustomization`**: an application, a change, a drift, a prune, a suspend and a revert.
4. **Layers**: `dependsOn` and `wait`, and a broken layer that blocks what depends on it.
5. **Secrets**: the options in slides, then SOPS and age: the mistake, the key, the encrypted file, the decryption, and who reads what.
6. **Tenants**: an account per team, and a request the API server refuses.
7. **Many clusters**: a second cluster, the same files, its own key, and a patch.
8. **Terraform** in slides: one resource bootstraps a cluster.
