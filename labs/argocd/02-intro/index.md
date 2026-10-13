# Argo CD

A GitOps controller for Kubernetes, with a web interface, an API and a command line.

---

## What it is

- **A Kubernetes controller**: the documentation says it "continuously monitors running applications" and compares the live state with the target state in Git.

- **An application is a resource**: an `Application` names a source (a repository, a revision, a path) and a destination (a cluster, a namespace).
  Everything Argo CD is told is a resource of its own namespace, so it can be kept in Git too.

- **What a source can be**: plain YAML, Kustomize, Helm, Jsonnet.
  Argo CD renders them, it does not run `helm install`.

- **What it adds to the loop of the GitOps course**: a state per application (`Synced` or `OutOfSync`, `Healthy` or not), a visual diff, history and rollback, hooks and waves, access control and SSO, many clusters.

- Reference: [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/).

---

## How it works

![Argo CD pulls a Git repository, renders the manifests, applies them to the hub cluster and to registered clusters, and compares them with the live state, with a web interface and a command line for people](../assets/argocd-dark.svg#gh-dark-mode-only)
![Argo CD pulls a Git repository, renders the manifests, applies them to the hub cluster and to registered clusters, and compares them with the live state, with a web interface and a command line for people](../assets/argocd.svg#gh-light-mode-only)

---

## The parts

Part                       | What it does, from the documentation
---------------------------|--------------------------------------------------------------------------------------------------
API server                 | "A gRPC/REST server which exposes the API consumed by the Web UI, CLI, and CI/CD systems", with authentication and RBAC
Repository server          | Keeps a local cache of the repository, and is "responsible for generating and returning the Kubernetes manifests"
Application controller     | Compares the live state with the target state, detects `OutOfSync`, and optionally corrects it
ApplicationSet controller  | Makes Applications from generators: a list, the folders of a repository, the clusters of Argo CD
Redis, Dex, notifications  | A cache, an identity broker for SSO, and messages about the state of the applications

- The lab installs them with the manifest of one release, and `kubectl get pods` shows each of them.

---

## Who maintains it

- **A CNCF project**: Argo was accepted on 26 March 2020 at the incubating level and graduated on 6 December 2022.
  Its first commit is dated 27 July 2017, and the CNCF page counts 15,199 contributors from 3,293 organizations (LFX Insights, read on 13 October 2026).

- **Its origin**: Applatix open sourced the Argo project in 2017, Intuit acquired Applatix in 2018, and Argo CD, Rollouts and Events were added.
  Three of the founding engineers of Applatix later founded Akuity, according to its own page.

- **Who maintains it today**: the roster of the Argo project, read on 13 October 2026, lists 42 people with a role on Argo CD (reviewer, approver or lead), from 16 organizations, two independent and one with no affiliation.
  Akuity and Red Hat count 8 each, Intuit 7 and Octopus Deploy 4.
  The authoritative file is `maintainers.yaml` of the repository `argoproj/.project`.

- **Governance**: reviewers, approvers and leads are the maintainers, most issues are settled by consensus, then by a vote, and "no organization may hold more than 40% of eligible votes".

- **Release cadence**: a minor version every three months, about, and only the three most recent minor versions get patches.
  The lab uses v3.5.5, published on 12 October 2026.

- References: [CNCF](https://www.cncf.io/projects/argo/), [governance](https://github.com/argoproj/argoproj/blob/main/community/GOVERNANCE.md), [maintainers](https://github.com/argoproj/argoproj/blob/main/MAINTAINERS.md), [release process](https://argo-cd.readthedocs.io/en/stable/developer-guide/release-process-and-cadence/), [Akuity](https://akuity.io/company).

---

## What is specific to it

Feature                  | What it means
-------------------------|--------------------------------------------------------------------------------------------------------
The user interface       | A tree of every resource of an application, its health, a diff of the live state against Git, one click to sync
`ApplicationSet`         | One resource that makes many Applications: one per folder of a repository, one per cluster
`AppProject`             | A tenant: which repositories, which clusters and namespaces, and which roles
Sync phases and waves    | `PreSync`, `Sync`, `PostSync` hooks, and an order inside a sync with `argocd.argoproj.io/sync-wave`
Rollback                 | To any revision kept in the history of an application, until automated sync is turned on
Many clusters            | A cluster is a Secret of the namespace of Argo CD, with a label that a generator can select

---

## Strengths and weaknesses

Strength                                                | Weakness, stated by the documentation
--------------------------------------------------------|----------------------------------------------------------------------------------------------------------
The state of every application is visible and shared    | Helm is only used "to inflate charts with `helm template`": no `helm list`, and only part of the hooks are mapped
A diff before and after, and an audit of who synced     | A sync is attempted once per commit: a failed one is not retried unless `retry` is set
Access control, SSO and tenants (AppProject) are built in | The `admin` account is for the first configuration, then it is disabled
One hub holds many clusters                             | The hub holds the credentials of every cluster, as Secrets of its namespace, and acts with a `cluster-admin` level role by default
A CNCF graduated project with many maintainers          | Pruning is off by default, and a rollback is refused while automated sync is on
                                                        | Secrets are left to other tools: the documentation advises against injecting them while rendering

- **A weakness is a trade**: each of these is a choice Argo CD made, and the lab shows several of them before the best practices that answer them.

- References: [Helm](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/), [automated sync](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/), [security](https://argo-cd.readthedocs.io/en/stable/operator-manual/security/), [users](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/), [secrets](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/).

---

## Secrets

The documentation takes a side: "populate secrets on the destination cluster" with a tool made for it, so that Argo CD never holds them.

Option                    | What the repository holds                                      | What it ties the team to
--------------------------|----------------------------------------------------------------|--------------------------------------------------------
Sealed Secrets            | A `SealedSecret`, encrypted for one cluster                    | The key of each cluster, to back up; a file per cluster
External Secrets Operator | An `ExternalSecret`, a pointer to a secret manager             | The secret manager, and an access per cluster
SOPS with a plugin        | A file encrypted with a key (age, a cloud KMS)                 | A plugin of the repository server: Argo CD sees the clear value
Vault plugin at render    | A placeholder, filled while the manifests are rendered         | The documentation "strongly" cautions: the result is cached in clear in Redis

- **What Argo CD adds to the choice**: the manifests are rendered by its repository server and cached, so a secret that exists at render time exists in its cache too, and the cluster Secrets of its own namespace open every cluster.
- **The lab uses Sealed Secrets**, which needs no account: the controller comes from the platform layer of the root, and the sealed file of the shop is read by Argo CD like any other.
- Reference: [secret management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/).

---

## In this lab

Step         | What it shows
-------------|--------------------------------------------------------------------------------------------------------------
Setup        | Docker Engine, k3d, kubectl, Gitea, the Argo CD command line, from checked binaries
Install      | The manifest of a release, the parts as Pods, the web interface and the first login, by a link
Application  | A read-only credential, an application that is `OutOfSync`, its diff, a sync, the tree and its panels, the history
Sync policy  | Automated sync, self-heal, prune, `ignoreDifferences`, and why a rollback is refused
Bootstrap    | An ApplicationSet per folder, a root Application, and an order between layers that only works with a health check
Secrets      | A `SealedSecret` in Git, the controller delivered by the root, and the key that is the cluster
Projects     | An `AppProject` as a tenant, an Application refused for its namespace, an account and its role
Many clusters | The design in slides, then a second cluster registered by a Secret and one ApplicationSet for both
Terraform    | In slides: the providers, what a new environment needs, and the files that were run against real clusters

> One virtual machine and no account: Gitea is the Git server, and the clusters are k3d clusters.
