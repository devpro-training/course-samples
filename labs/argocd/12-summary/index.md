# Summary

---

## Cheat sheet

Task                                 | Command
-------------------------------------|-------------------------------------------------------------------------------
Install a release                    | `kubectl apply --namespace argocd --server-side --force-conflicts --filename <manifest>`
First password                       | `argocd admin initial-password --namespace argocd`
Log in                               | `argocd login <host:port> --username admin` (`--plaintext` with no TLS)
Applications, one of them            | `argocd app list`, `argocd app get <app> --refresh`
Difference with Git                  | `argocd app diff <app>`, which exits with 1 when there is one
Sync, and wait                       | `argocd app sync <app>`, `argocd app wait <app> --health`
History, and go back                 | `argocd app history <app>`, `argocd app rollback <app> <id>` (refused with automated sync)
End a sync that waits                | `argocd app terminate-op <app>`
Repositories, clusters, projects     | `argocd repo list`, `argocd cluster list`, `argocd proj list`
Leave a field to another controller  | `ignoreDifferences` in the Application, by `jsonPointers`, `jqPathExpressions` or `managedFieldsManagers`
Seal a Secret for a cluster          | `kubeseal --controller-namespace <ns> --format yaml < secret.yaml > sealed.yaml`
An account and its role              | `accounts.<name>: login` in `argocd-cm`, `g, <name>, role:<team>` in `argocd-rbac-cm`
Where a repository or a cluster is   | A Secret of the namespace `argocd`, labeled `argocd.argoproj.io/secret-type: repository` or `cluster`

---

## Where things are

What                               | Where
-----------------------------------|----------------------------------------------------------------------
The desired state                  | The branch `main` of the repository `deploy`
The layers                         | The folder `bootstrap`, read by the Application `root`
One folder per application         | The folder `apps`, read by the ApplicationSet `apps`
Its credential                     | A token of Gitea with `read:repository`, in a Secret of the namespace `argocd`
The health of an Application       | `resource.customizations.health.argoproj.io_Application` in `argocd-cm`
The clusters                       | Secrets labeled `argocd.argoproj.io/secret-type: cluster`, written by hand or by Terraform
The secrets                        | `SealedSecret` files next to the manifests, and the key of the controller backed up outside
The teams                          | An `AppProject` each, in `bootstrap`, and the roles of `argocd-rbac-cm`
The files of the lab               | `~/lab/argocd` of the machine

---

## Best practices

- **Pin everything**: the release of Argo CD, the chart, the `targetRevision` of an environment that matters, the images.
  A tracked `HEAD` or `latest` is a deployment nobody decided.

- **Disable `admin`** once SSO or a local user exists, and delete the Secret of the generated password: the documentation says to use it "only for initial configuration", then set `admin.enabled` to `"false"`.

- **Give it a project, not `default`**: an `AppProject` limits the repositories, the clusters and namespaces and the roles of a team.

- **Read-only credentials for Git**, and Secrets that Argo CD does not render: the documentation recommends filling them on the cluster, with Sealed Secrets or External Secrets Operator, and cautions against injecting them while rendering, since they would be cached in clear in Redis.

- **Secrets are sealed or referenced, never rendered**: a `SealedSecret` per cluster with its key backed up, or an `ExternalSecret` that points to a store.

- **Tell Argo CD what it does not own**: `ignoreDifferences` for the fields of an autoscaler or a webhook, written in the Application so that the decision is in Git.

- **Prune and self-heal on, rollback by revert**: drift is corrected, deletion follows Git, and the history of Git is the history of the cluster.

- **A webhook from the Git server**, since the default look at the repository is every 3 minutes at most.

- **Order layers with a health check**: waves between Applications only wait when the health of an Application is assessed.

- **Keep the control plane small**: one repository for the cluster configuration, apart from the one of the application code, and the access to the namespace `argocd` as strict as the access to the clusters.

- **Back up and monitor Argo CD**: a hub that stopped is a set of clusters that silently stopped following Git.

---

## Mistakes seen in the lab

Mistake                                          | What happened
-------------------------------------------------|-----------------------------------------------------------------------------------
A typo in the path of a layer                    | The root said `waiting for healthy state`, and the layers after it did not start
No health check on Applications                  | The waves created everything at once, with the broken layer next to the others
A rollback with automated sync                   | Refused, since the controller would undo it
A file removed with no `prune`                   | The Service stayed, and the application was `OutOfSync`
A team Application for another namespace         | Created, and invalid: the project did not allow the destination
The address of the cluster taken from a kubeconfig | A port of the machine that a Pod does not reach, so the Secret names the container

---

## Next

Need                           | Next
-------------------------------|-----------------------------------------------------------
The same loop, as a toolkit    | **Flux**: sources and Kustomizations as resources of the cluster
A fleet of clusters            | **Rancher**, with Fleet, or the project `argocd-agent`
Progressive delivery           | Argo Rollouts, the sibling project, for canary and blue/green
Who may talk to whom           | **Zero trust** and **NeuVector**
What the cluster does          | **Observability**: the three pillars

- Reference: [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/), [declarative setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/), [cluster bootstrapping](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/), [ApplicationSet](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/), [argocd-agent](https://argocd-agent.readthedocs.io/latest/).
