# Secrets in a GitOps repository

Git holds everything the cluster should be, and a password is part of it.
It cannot be in clear: a repository is cloned, forked, cached and kept forever.

---

## The problem

- **Base64 is an encoding**: the manifest of a Secret shows the value to anyone who reads the file, and the lab decodes it in one command.
- **Git keeps its history**: a value removed by a later commit is still in the older ones, on every clone.
- **A leaked secret is rotated**, not deleted: the repository can only be made safe by changing the value.
- **The documentation of Flux says it plainly**: keep plain-text secrets out of the desired state, and use a native Secret only for the first credential, the one of the source.

---

## Three places for a secret

Place                          | Git holds                         | Who decrypts or fetches        | Example
-------------------------------|-----------------------------------|--------------------------------|---------------------------
In Git, encrypted              | The ciphertext                    | A controller of the cluster, with a key | SOPS, Sealed Secrets
Outside the cluster, in a store | A reference to the secret         | An operator, with an identity   | External Secrets Operator, a CSI driver
Only in the cluster            | Nothing                           | Nobody: created by hand        | The first credential

- **A team often uses two**: SOPS or a store for the secrets of applications, and a manual one for the key that opens them.
- **Reference**: [Flux, secrets management](https://fluxcd.io/flux/security/secrets-management/).

---

## SOPS

- **What it does**: encrypts the values of a YAML file and leaves the keys readable, so a review and a `git diff` still say what changed.
- **How**: a random data key encrypts the values, and the data key is encrypted for each recipient, in a block `sops:` of the file, with a MAC that detects a changed file.
- **Which keys**: age and OpenPGP offline, or AWS KMS, Azure Key Vault, GCP KMS, OpenBao and Vault, as the documentation of the `Kustomization` lists.
- **Where Flux decrypts**: in the `kustomize-controller`, with `spec.decryption`, "without the need of additional controllers installed in the cluster".

![SOPS encrypts a secret with the public key, Git holds the ciphertext, and the kustomize controller decrypts it with the private key held in a Secret of the cluster and applies the Secret](../assets/flux-secrets-dark.svg#gh-dark-mode-only)
![SOPS encrypts a secret with the public key, Git holds the ciphertext, and the kustomize controller decrypts it with the private key held in a Secret of the cluster and applies the Secret](../assets/flux-secrets.svg#gh-light-mode-only)

---

## SOPS: what it needs, what it ties the team to

- **Needs**: `sops` and a key tool on the machine of the people who write secrets, a `.sops.yaml` of the repository, and a Secret with the private key in each cluster.
- **Ties the team to**: its file format, a key to keep and rotate, and a store (a KMS or Vault) that becomes "a single point of failure if it is deleted or unavailable for long periods", per the Flux documentation.
- **Limit**: the history keeps what was encrypted with an old key, so a leaked old key opens the old values.
- **Limit**: the people who write a secret can read it, since they have the value, and the people who can only review see the structure.

---

## Sealed Secrets

- **What it does**: a controller in the cluster holds a private key, and `kubeseal` encrypts a Secret with its certificate into a `SealedSecret`, a resource safe to keep in Git.
- **What the Flux documentation says of this family**: ciphertext is stored "as Kubernetes resources within a Flux source", and the decryption is transparent to the applications.
- **Needs**: the controller installed before the first `SealedSecret`, which is a layer of its own, and the certificate of each cluster.
- **Ties the team to**: a controller to run and a key per cluster, so the same file is not valid in two clusters.
- **Limit**: as for SOPS, "sources can keep a history of encrypted secrets", so a leaked old key exposes more.

---

## External secrets

- **What it does**: External Secrets Operator reads a `SecretStore` (how to authenticate to AWS Secrets Manager, Azure Key Vault, HashiCorp Vault, Google Cloud Secret Manager and others), and an `ExternalSecret` (which data to fetch).
  It "fetches secrets from an external API and creates Kubernetes secrets".
- **Git holds a reference**, never a value, so a leak of the repository leaks nothing, and the store keeps the audit and the rotation.
- **Needs**: a store, an identity for the operator, and a plan for the store being down.
- **Ties the team to**: the store and its rate limits, since the Flux documentation warns that a large number of secrets slows the creation of a cluster.
- **A CSI driver** mounts the secret as a file in the Pod: the control plane never sees it, so a resource that names a Secret, such as the `secretRef` of a `GitRepository`, cannot use it.

---

## The key of the keys

- **Somebody gives the cluster its first secret**: the SOPS private key, the key of Sealed Secrets, or the identity of the operator.
- **Flux's own credential is one too**: the token that reads the repository is a Secret of the namespace of Flux, readable by whoever reads that namespace.
- **Keep it outside the cluster as well**: a password manager or a vault, since a cluster lost with its only key loses every value.
- **Test a rebuild from nothing**: the documentation asks for it, especially when a secret depends on a CRD that a later `Kustomization` deploys.

---

## Good practices

- **One key per cluster or environment**, and a production secret in a file only the production key opens.
- **Least privilege**: a token with the one scope it needs, an account for each tenant, and a namespace per team.
- **Rotation**: values and keys expire, and the old and the new coexist while the new is checked.
- **Do not keep keys beside the ciphertext**: no `age.agekey` in the repository, and no `.sops.yaml` rule for a key the cluster does not hold.
- **Kubernetes Secrets are stored in etcd** "either in plain-text or encrypted": encryption at rest is a setting of the cluster, as the k3s course shows, and RBAC decides who reads a namespace.
- **A layered approach**: the documentation says it is recommended, since the weakest link matters most.
