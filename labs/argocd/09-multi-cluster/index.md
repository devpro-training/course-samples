# Many clusters

One Argo CD can deploy to every cluster of a company.
The question is not how to add the second cluster, which the next step does, but how to organize the repository, the labels and the credentials so that the twentieth costs nothing.

---

## A cluster is a Secret

A cluster is declared to Argo CD by a Secret of its namespace.
The label says what it is, and the labels that follow are the vocabulary of the organization:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cluster-prod-eu
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    env: prod
    region: eu
stringData:
  name: prod-eu
  server: https://prod-eu.example.com:6443
  config: |
    {"bearerToken": "<token>", "tlsClientConfig": {"caData": "<base64 of the CA>"}}
```

- `argocd cluster add` makes the same Secret, with a ServiceAccount `argocd-manager` in the cluster, and it takes the address from the kubeconfig.
- The documentation says Argo CD "stores the credentials of the external cluster as a Kubernetes Secret in the argocd namespace".
- The local cluster has no Secret: `in-cluster`, and a selector on a label leaves it out.

---

## How to see many clusters

![A Git repository with a folder of the platform per environment and applications with a base and an overlay per environment is read by a hub cluster whose ApplicationSets select the clusters by label and make one Application per cluster and per application, for three clusters that each have their own labels and their own sealed key](../assets/argocd-clusters-dark.svg#gh-dark-mode-only)
![A Git repository with a folder of the platform per environment and applications with a base and an overlay per environment is read by a hub cluster whose ApplicationSets select the clusters by label and make one Application per cluster and per application, for three clusters that each have their own labels and their own sealed key](../assets/argocd-clusters.svg#gh-light-mode-only)

---

## Three ways to organize it

Topology                       | How it works                                                                       | What it costs
-------------------------------|------------------------------------------------------------------------------------|---------------------------------------------------------
One hub                        | One Argo CD, the clusters are Secrets, ApplicationSets select them                 | The hub holds a credential per cluster, and is a failure domain
One Argo CD per cluster        | Each cluster pulls its own folder, `clusters/<name>`, and reads Git only           | A view per cluster, and the same upgrade many times
Hub with agents                | `argocd-agent`: agents on the clusters connect out to a central control plane      | A newer project: "active development with a stable core architecture", in its own words

- **The hub is where most start**: the credentials are the weak point, so the identity of Argo CD in each cluster is narrowed to what it deploys, and the Secrets of the namespace `argocd` are protected as the clusters they open.
- **Clusters that cannot be reached**, behind a firewall or a NAT, or air-gapped, are what the agents are for: the controllers run where the workloads are, and connect out.

---

## The repository

```txt
bootstrap/                 the root points here: the ApplicationSets and the projects
platform/<env>/            what every cluster of an environment gets
apps/<app>/base/           the manifests, or the chart, once
apps/<app>/overlays/<env>/ what differs per environment: replicas, host names, sealed secrets
```

- **A folder per environment, not a branch**: one history, a diff between two environments is a diff between two folders, and a promotion is a pull request that copies a change from `staging` to `prod`.
- **Kustomize overlays or Helm values per environment**: Argo CD renders both, and the choice is the one of the team.
- **Nothing per cluster in the Applications**: everything that differs comes from the labels of the Secret.

---

## One ApplicationSet for every cluster and every application

The matrix generator combines two children: the folders of `apps` and the clusters, and makes one Application per pair.
The documentation says its children are two, and that it can only be nested once:

```yaml
generators:
  - matrix:
      generators:
        - git:
            repoURL: https://git.example/deploy.git
            revision: main
            directories:
              - path: apps/*
        - clusters:
            selector:
              matchExpressions:
                - key: env
                  operator: Exists
template:
  metadata:
    name: '{{.path.basename}}-{{.name}}'
  spec:
    project: default
    source:
      repoURL: https://git.example/deploy.git
      targetRevision: main
      path: '{{.path.path}}/overlays/{{.metadata.labels.env}}'
    destination:
      server: '{{.server}}'
      namespace: '{{.path.basename}}'
```

- `{{.metadata.labels.env}}` is the label of the cluster Secret: a new cluster labeled `prod` gets every application at its `prod` overlay, with no file to write.
- **The platform is another ApplicationSet**, on the clusters alone, in the first wave, with the path `platform/{{.metadata.labels.env}}`.
- The `values` field of the cluster generator passes other strings to the template, such as a revision per environment.

---

## Rolling it out, cluster by cluster

A change that reaches every cluster at once is the same incident everywhere.
Progressive syncs, a beta feature since v3.3.0 that is turned on explicitly, order the Applications of an ApplicationSet by a label:

```yaml
spec:
  strategy:
    type: RollingSync
    rollingSync:
      steps:
        - matchExpressions:
            - key: env
              operator: In
              values: [staging]
        - matchExpressions:
            - key: env
              operator: In
              values: [prod]
          maxUpdate: 10%
```

- The controller syncs the staging Applications, waits for them to be `Healthy`, then updates prod by 10% at a time.
- The Applications that no step matches are left out, and are synced by hand.
- The labels are put on the Applications by the template, from the labels of the cluster.

---

## Secrets with many clusters

- **One key per cluster with Sealed Secrets**: a file of Git is sealed for one controller, so the file lives in the overlay of the environment, and a copy for another cluster is another file.
  The key of each cluster is backed up outside of the cluster and of Git.

- **A secret store with External Secrets Operator**: the repository holds a reference, the same for every cluster, and each cluster has its own access to the store.
  Nothing is sealed, and the store becomes a dependency of every cluster.

- **Never one shared key and one shared ciphertext for every cluster**: a leak of one cluster opens them all.

- **The cluster Secrets of the hub are secrets too**: they are made by Terraform or sealed for the hub, and never written by hand in Git.

---

## Teams and clusters

- **An `AppProject` per team** lists the clusters and namespaces it may write to, as a pair of server and namespace, and the repositories it may read.
  The team of a project cannot deploy to a cluster the project does not name.

- **The RBAC maps groups to projects**: the groups of the identity provider, through SSO, and `g, <group>, role:<team>`.

- **The platform team owns the projects and the cluster Secrets**, the application teams own their folders: the repository has code owners for each.

---

## What breaks first

Symptom                                         | Cause, and what to look at
------------------------------------------------|------------------------------------------------------------------------------------------
An Application is `Unknown` for one cluster     | The credential or the path to the API server: `argocd cluster list` shows the connection status
Every Application of a cluster is `OutOfSync`   | A webhook or a controller changes fields: `ignoreDifferences`, or the managers that own them
The hub is slow with many Applications          | Polling every 3 minutes (a webhook on `/api/webhook`), and the controller: clusters are sharded across its replicas, and the repository server has a limit of manifests generated at once
A sealed file does not open on a cluster        | It was sealed for another cluster's key
Everything changes at once                      | No progressive sync, no environments in the order of risk

- **A new environment is one Secret**, and the cost of the twentieth cluster is the cost of that Secret, if the labels and the overlays are what carry the differences.
- References: [cluster generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/), [matrix generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/), [progressive syncs](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Progressive-Syncs/), [argocd-agent](https://argocd-agent.readthedocs.io/latest/).
