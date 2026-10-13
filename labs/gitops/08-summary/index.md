# Summary

---

## Cheat sheet

Task                         | Command
-----------------------------|-----------------------------------------------------------------------
Render an environment        | `kubectl kustomize <folder>`
Apply an environment         | `kubectl apply -k <folder>`
Compare with the cluster     | `kubectl diff -k <folder>`, which exits with 1 when they differ
Prune what files dropped     | `kubectl apply -k <folder> --prune --selector <label> --prune-allowlist <group/version/kind>`
Ask a server for its branches | `git ls-remote origin`
Search the history for a text | `git log --oneline -S <text>`
Undo a merge                 | `git revert --mainline 1 <merge commit>`
Can this account do it       | `kubectl auth can-i <verb> <resource>`
Make a token                 | `POST /api/v1/users/<user>/tokens` on Gitea, with `scopes`

---

## Where things are

What                    | Where
------------------------|----------------------------------------------------------------------
The desired state       | The branch `main` of the repository, folder `envs/<environment>`
The reconciler               | `reconcile.sh`, and its output in `reconcile.log`
Its credential          | A token of Gitea with `read:repository`, in the file `token`
The Git server          | `gitea web`, with `/etc/gitea/app.ini` and `/var/lib/gitea`
What the reconciler owns     | The objects labeled `app.kubernetes.io/managed-by=reconciler`

---

## Tips

- **Read-only for the reconciler**: its Git credential only reads, so a compromised cluster cannot rewrite the history.

- **One change, one pull request**: small, reviewed, and revertible.

- **Keep the CI for what comes before the merge**: tests, scans, building, and writing the new image tag into the repository.

- **Look at the difference before the merge**: the diff of the pull request is the diff of the cluster.

- **A rollback is a revert**, a commit like the others.

- **Name the owner of each object**: a label, an inventory, so a deletion in Git is a deletion in the cluster, and nothing else is.

---

## Good practices

- **Never store a secret value in Git**: it never forgets, and when it happens, the secret is generated again.

- **Encourage the collaboration of build and run**: the developers and the operators help each other with the Dockerfile and the charts.

- **Follow one branching standard**: Git Flow, GitHub Flow or GitLab Flow, since many problems come from the way the branches are used.

- **Keep your own application catalog**: the applications that can be used are validated and shared.

- **Start small**: a non-production environment, one component at a time, then share and improve.

- **Monitor the reconciler**: a cluster that stopped following Git looks healthy.

---

## Where it fits

Level          | Practices
---------------|--------------------------------------------------------------------------------
Awareness      | Git versioning, manual deployments
Adoption       | CI/CD pipelines, merge requests, unit tests and SAST, automated deployments
Integration    | Automated testing, artifact scanning, continuous deployment, monitoring, Infrastructure as Code
Optimization   | **GitOps (pull)**, unified observability, proactive security, high availability, FinOps
Mastery        | Predictive security, self-service portals, AI-driven processes

- The levels come from the author's talk "Cloud Native DevOps" (July 2025): GitOps in pull mode is a step of optimization, after pipelines and Infrastructure as Code.

---

## Natural next steps

Need                              | Next
----------------------------------|----------------------------------------------------------------------
A real reconciler, with a UI           | **Argo CD**: applications, sync status, self-heal, Helm
A real reconciler, a toolkit           | **Flux**: sources and Kustomizations as resources of the cluster
Many clusters                     | **Rancher**, with Fleet
Who may talk to whom              | **Zero trust** and **NeuVector**
What the cluster does             | **Observability**: the three pillars

- Reference: [OpenGitOps](https://opengitops.dev/), [Argo CD](https://argo-cd.readthedocs.io/en/stable/), [Flux](https://fluxcd.io/flux/concepts/), [Fleet](https://fleet.rancher.io/).
