# Summary

What was run, what to keep, and what comes next.

---

## Cheat sheet

Task                                  | Command
--------------------------------------|----------------------------------------------------------------------------------
Check the cluster                     | `flux check --pre`, `flux check`
Install Flux and its folder           | `flux bootstrap git --url <url> --branch main --path clusters/<name> --token-auth ...`
Write an object instead of typing it  | `flux create kustomization <name> --source GitRepository/flux-system --path <folder> --export`
Look at everything                    | `flux get all`, `flux get kustomizations`, `flux tree kustomization flux-system`
Ask for a reconciliation now          | `flux reconcile kustomization <name> --with-source`
Pause and resume                      | `flux suspend kustomization <name>`, `flux resume kustomization <name>`
Give the controller a key             | `kubectl create secret generic sops-age --from-file=age.agekey=<file>`
Encrypt a file for a recipient        | `sops --encrypt --in-place <file>`, with a `.sops.yaml`
Add a recipient                       | `sops updatekeys <file>`
A tenant                              | `flux create tenant <name> --with-namespace <ns> --cluster-role admin --export`

---

## What to remember

- **The cluster pulls**: nothing outside needs a credential for it, and the repository is the only way in.
- **A layer is a `Kustomization`**: `dependsOn` for the order, `wait` for the health, `prune` for the removal, `suspend` for the incident.
- **Git is the history**: a revert is a commit, and the history says who changed what.
- **A secret is encrypted before it is committed**: the key is the secret of secrets, kept outside the cluster too.
- **A tenant has an account**: the controller impersonates it, and Kubernetes refuses the rest.
- **One Flux per cluster**: the same files, a patch for what differs, a key of its own.

---

## Good practices

- **One repository, three folders**: `clusters`, `infrastructure`, `apps`, with a layer per `Kustomization`.
- **Pin what is installed**: a chart version, an image tag or a digest, a release of Flux.
- **Set `timeout` and `wait`** on a layer, so a broken one says so and blocks what depends on it.
- **Name the account** of every `Kustomization` and `HelmRelease` of a tenant, and set the default account of the controllers.
- **Rotate keys and tokens**, with the old and the new valid together while the new is checked.
- **Test a rebuild from nothing**, with the repository and the key as the only inputs.
- **Add a UI if the team needs one**, from the ecosystem, without changing how Flux is run.

---

## What was not covered

- **Image automation**: `ImageRepository`, `ImagePolicy` and `ImageUpdateAutomation` scan a registry and commit new tags to Git. They are not installed by a bootstrap, and `--components-extra` adds them.
- **OCI sources**: an `OCIRepository` pulls manifests from a registry instead of Git, with the same sources and the same objects after it.
- **Notifications**: a `Provider` and an `Alert` send the events to a chat or a Git host, and a `Receiver` takes a webhook to reconcile at once.
- **Remote clusters**: `spec.kubeConfig`, as the slides of the many clusters describe.

---

## Next

- **The series**: Rancher, zero trust, NeuVector, then observability with Prometheus and Grafana, which read the state of Flux.
- **Before**: The courses GitOps, Helm and Argo CD are the courses this one builds on and compares with.
- **Reference**: [Flux documentation](https://fluxcd.io/flux/), [guides](https://fluxcd.io/flux/guides/), [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example).
