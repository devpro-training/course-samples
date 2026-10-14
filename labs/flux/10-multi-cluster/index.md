# Many clusters

A team rarely runs one cluster: there are environments, regions, customers, and each is a cluster.
Flux has two designs for them, and the choice is about where the credentials live.

---

## One Flux per cluster

![One repository holds a folder per cluster and the folders of the applications they share, and each cluster runs its own Flux that follows its own folder, with its own key for the secrets](../assets/flux-clusters-dark.svg#gh-dark-mode-only)
![One repository holds a folder per cluster and the folders of the applications they share, and each cluster runs its own Flux that follows its own folder, with its own key for the secrets](../assets/flux-clusters.svg#gh-light-mode-only)

---

## The repository

The documentation recommends one repository, a monorepo, with three folders:

```txt
├── apps
│   ├── base
│   ├── production
│   └── staging
├── infrastructure
│   ├── base
│   ├── production
│   └── staging
└── clusters
    ├── production
    └── staging
```

- **`clusters/<name>`** holds what a cluster follows: the bootstrap, and the `Kustomization` of each layer, with `dependsOn` for the order.
- **`infrastructure/`** is what every cluster needs before the applications (ingress, certificates, policies), and `apps/` is what runs on it.
- **`base` and one overlay per environment**: the overlay differs from the base by a patch, as the lab does with the replicas of the staging.
- **The documentation names three more**: a repository per environment, per team, per application, each with its own rights on who writes where.

---

## How a new cluster joins

1. **Create the cluster**, with whatever makes clusters.
2. **Bootstrap Flux** on it, with `--path clusters/<name>`: the same command each time, the lab ran it twice.
3. **Give it its key** for the secrets, the only manual act.
4. **Commit its folder**: copies of the layers, and the patches that make it different.
5. **Flux does the rest**, layer after layer, and the cluster reports its own state.

- Nothing is registered anywhere else, and no other cluster is told.
- Removing a cluster is deleting its folder and the cluster, and nothing in the others changes.

---

## The credentials

Design                                 | Who holds what                                                             | Failure domain
---------------------------------------|----------------------------------------------------------------------------|----------------------------
One Flux per cluster                   | Each cluster holds a token that reads the repository, and its own SOPS key | One cluster
A hub that applies to others           | The hub holds a kubeconfig, or an identity, for every cluster it manages   | The hub and all its targets
A hub with `kubeConfig` and an account | The same, and the hub impersonates a ServiceAccount of each target         | Narrower, if the account is

- **A hub is a `Kustomization` or a `HelmRelease` with `spec.kubeConfig`**: it applies on a remote cluster, from a `secretRef` that holds a kubeconfig, or a `configMapRef` with a workload identity (AWS, Azure, GCP).
- **With `serviceAccountName` too**, the controller impersonates that ServiceAccount on the target, which must exist there in a namespace with the same name as the `Kustomization`.
- **For Cluster API**, the `Kustomization` sits in the namespace of the `Cluster` and reads the Secret `<cluster>-kubeconfig` that Cluster API creates.

---

## Secrets in many clusters

- **One key per cluster, or per environment**: the file is encrypted for several recipients, and each cluster holds only the private key it needs.
- **`sops updatekeys`** adds or removes a recipient with no change to the values, and the old history stays readable by the old key.
- **A production secret is a different file** from the staging one, encrypted for the key of production only, so the staging cluster cannot read it.
- **A cloud KMS or Vault** removes the private key from the cluster, and makes the store a dependency of every cluster.

---

## Choosing

Choose               | When
---------------------|--------------------------------------------------------------------------------------------------------------------------
One Flux per cluster | Clusters are many, in different networks or owned by different teams, and a credential must not leave a cluster
A hub                | The clusters are few, one team runs them all, and one place to look is worth a credential for each
A UI on top          | In both cases, to see the state of the clusters in one screen: the Flux Operator, Headlamp, Capacitor, a Backstage plugin

- Flux and the lab keep the first design, since it is the one with no credential that leaves a cluster.
- An observability stack can gather the state of every Flux, which is in the status of its objects.
