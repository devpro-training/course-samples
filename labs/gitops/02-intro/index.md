# GitOps

Git is the source of truth of an environment, and a reconciler makes the cluster match it.

---

## The problem

- **A cluster is changed by many hands**: a pipeline, a person with `kubectl`, a script, a Helm command typed during an incident.

- **Nothing says what should be there**: the pipeline knows what it last applied, not what the cluster holds now.

- **The pipeline holds the keys**: to push, a system outside the cluster has the credentials to change it, and the cluster accepts connections from it.

- **Drift is silent**: the lab shows a change made by hand that stays for as long as nobody looks.

- **Rolling back is a new deployment**, with the same pipeline, the same credentials, and the same hurry.

---

## How it works

![People merge changes into a Git repository, a reconciler inside the cluster pulls the repository, applies it to the actual state, observes it, and undoes the drift; a push pipeline from outside is shown for comparison](../assets/gitops-dark.svg#gh-dark-mode-only)
![People merge changes into a Git repository, a reconciler inside the cluster pulls the repository, applies it to the actual state, observes it, and undoes the drift; a push pipeline from outside is shown for comparison](../assets/gitops.svg#gh-light-mode-only)

---

## The principles

OpenGitOps, overseen by the GitOps Working Group, states four principles, in version 1.0.0:

Principle               | Wording
------------------------|------------------------------------------------------------------------------------------------------------------
Declarative             | "A system managed by GitOps must have its desired state expressed declaratively."
Versioned and immutable | "Desired state is stored in a way that enforces immutability, versioning and retains a complete version history."
Pulled automatically    | "Software agents automatically pull the desired state declarations from the source."
Continuously reconciled | "Software agents continuously observe actual system state and attempt to apply the desired state."

- The first two are about the repository, the last two about the program that keeps the cluster equal to it.
  The principles call it a software agent, and this course calls it the **reconciler**, since it reconciles the actual state with the desired one, and since "agent" has other meanings.

- Reference: [opengitops.dev](https://opengitops.dev/).

---

## Push and pull

Question                         | Push (a pipeline applies)        | Pull (a reconciler inside applies)
---------------------------------|----------------------------------|--------------------------------------------------
Who holds the cluster credential | The pipeline, outside            | The reconciler, inside
What the cluster allows          | Connections from outside         | Connections to a Git server, out only
When the cluster is corrected    | When someone pushes              | Every interval
Drift                            | Unknown until a push or a `diff` | Reported, and undone if the reconciler is told to
Git credential                   | One that writes                  | One that only reads

- **A pipeline stays useful** for what happens before a merge: tests, scans, building an image and writing its new tag in the repository.
  What it stops doing is touching the cluster.

- **Pull is not free**: a failing reconciler is a cluster that silently stops following Git, so its state is monitored like any other component.

---

## What the repository holds

- **Resources in files**: raw manifests, Helm charts, or Kustomize overlays, which `kubectl` carries.
  The lab uses Kustomize.

- **One folder, one branch or one repository per environment**: the three strategies exist, each with a cost.
  A folder per environment keeps one history and a visible difference between two; a branch per environment moves changes by merge, and a repository per environment gives each its own access rules.

- **A merge is a deployment**: so `main` is protected, a change is a pull request, and a review is the approval.

- **The history is the audit trail**: who changed what, when, and the message says why.

---

## Where the reconciler comes from

- **The term is credited to Weaveworks**, by the press that covered its closing, and its Flux was accepted by the CNCF on 15 July 2019.
  The company announced in February 2024 that it was closing, and Flux, a CNCF project, continues.

- **Two tools lead**:
  Argo CD joined the CNCF on 26 March 2020 and graduated on 6 December 2022, and Flux graduated on 30 November 2022.

- **Fleet** is the third, from the Rancher repositories, under the Apache-2.0 license, described as "GitOps and HelmOps at scale".

- **They all do the loop of the lab**, with a lot more care: many repositories, Helm, health checks, order of apply, notifications, a UI or a command line.

- References: [Argo CD](https://www.cncf.io/projects/argo/), [Flux](https://www.cncf.io/projects/flux/), [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/), [Flux concepts](https://fluxcd.io/flux/concepts/), [Fleet](https://fleet.rancher.io/).

---

## The loop of the lab

- **`kubectl apply -k`** applies a Kustomize folder, and `--prune` deletes what a file used to declare.

- **Pruning is alpha**: the Kubernetes documentation says the mode "has existed since kubectl v1.5 but is still in alpha due to usability, correctness and performance issues with its design", and warns that which objects are deleted depends on the flags.
  It recommends `--prune-allowlist` and a selector, which the lab uses, and `kubectl delete` as the explicit way.

- **Only an object that `kubectl apply` created is pruned**: it carries the annotation `kubectl.kubernetes.io/last-applied-configuration`.
  A Namespace or an object made by hand is left alone.

- **The real tools track what they own** on their own, with an inventory or labels, and that is one of the reasons they exist.

- Reference: [declarative management](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/).

---

## Secrets

- **A Secret in a manifest is base64**, which is an encoding.

- **Git never forgets**: a file removed in a later commit is still in the history, and so is the secret, which has to be changed.

- **The repository holds a reference or a ciphertext**, and the cluster holds the value:

Tool                      | What the repository holds
--------------------------|----------------------------------------------------------------------------
Sealed Secrets            | A `SealedSecret`, encrypted for one cluster, decrypted by a controller
SOPS                      | A file encrypted with a key (age, a cloud KMS), decrypted by the reconciler
External Secrets Operator | An `ExternalSecret`, a pointer to a secret manager
Vault Secrets Operator    | A resource that points to a path in Vault
Secrets Store CSI Driver  | A volume that mounts a secret from a manager

- Each ties the team to a component, and to the place where the key is kept.

---

## In this lab

Step               | What it shows
-------------------|---------------------------------------------------------------------------------------------------
Setup              | Docker Engine, k3d, kubectl and Gitea, from checked binaries
Repository         | A repository on Gitea, an application and an environment as files, the first commit
Push               | A `kubectl apply` from outside, the credential it needs, and drift nobody sees
Pull and reconcile | A read-only token, a short loop of shell, a change that follows a commit, drift undone, a deletion
Pull request       | A branch that changes nothing, a review, a merge, a revert
Secrets            | An encoding is not encryption, Git keeps everything, an object outside of Git

> One virtual machine and no account: Gitea is the Git server, and the reconciler is a script that is read, so every line of the loop can be seen.
