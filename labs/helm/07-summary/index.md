# Summary

---

## Cheat sheet

Task                         | Command
-----------------------------|-----------------------------------------------------------------------------------------
Add a catalog                | `helm repo add <name> <url>`
Search a catalog             | `helm search repo <word> --versions`
Read the settings of a chart | `helm show values <chart> --version <version>`
Read before installing       | `helm template <release> <chart>`, `helm pull <chart> --untar`
Install                      | `helm install <release> <chart> --version <version> -n <namespace> -f <values>`
Install or upgrade           | `helm upgrade --install <release> <chart> ...`
Wait, and go back on failure | `--wait --timeout 3m --rollback-on-failure`
What is installed            | `helm list -n <namespace>`, `helm get values <release>`, `helm get manifest <release>`
History and rollback         | `helm history <release>`, `helm rollback <release> <revision>`
Test a release               | `helm test <release> --logs`
Remove                       | `helm uninstall <release>`
Create, check, package       | `helm create`, `helm lint --strict`, `helm package`
Publish                      | `helm repo index <folder> --url <url>`, or `helm push <archive> oci://<registry>/<path>`

---

## Where things are

What                   | Where
-----------------------|-------------------------------------------------------------------------------------
A chart                | A folder: `Chart.yaml`, `values.yaml`, `values.schema.json`, `templates/`, `charts/`
A release              | The Secrets `sh.helm.release.v1.<release>.v<revision>` of its namespace
The known catalogs     | `helm repo list`, kept in the configuration folder of Helm
A chart repository     | `index.yaml` and the archives, on a web server or on the branch `gh-pages`
The releases on GitHub | The assets of a release per chart version, made by chart-releaser

---

## Tips

- **Pin the version of a chart**: `--version` everywhere, and a version bump is a pull request.

- **`helm upgrade --install`** is the one command of a pipeline, since it works the first time and every other.

- **`helm template` is the review tool**: the diff of its output between two versions is the diff of the cluster.

- **Values in files, in Git**: one file per environment, with only what differs.

- **A chart that changes bumps its `version`**: a published version is never replaced.

- **Flat, documented values with a schema**: a user reads `values.yaml` first.

- **Never change a selector**: the labels that select the Pods are one helper, and do not change.

---

## Good practices

- **Check the quality in the pipeline**: `helm lint --strict`, kube-linter on the rendered YAML, then `ct lint` and `ct install` of chart-testing in a throwaway cluster, with `helm test` as the proof.

- **Security context and resources by default**: a chart that runs as root with no limit is a bad default that most users keep.

- **No secret in values**: they are in the release Secret, and in `helm get values`.
  A reference to a secret that exists, or an external secret operator, is the way.

- **Keep your own catalog**: the charts the teams may use are validated, versioned and shared, and a copy of the public ones is a protection against the day one disappears.

- **Start simple**: a chart with two templates and three values is a chart, and `helm create` is a good source of ideas but not of a first chart.

---

## Security of the supply chain

A chart is a recipe that runs with the rights of the user, and it names images that run in the cluster.
Both are software from someone else, so both are part of the supply chain, as the courses on [application catalogs](../../app-catalog), [container security](../../container-security) and [Trivy](../../trivy) showed for images.

Question                            | What to do
------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Who publishes the chart?            | Prefer the project itself or a vendor with support, check its repository and its history, and know that a catalog (Artifact Hub) lists, and does not vouch
Is it the chart that was published? | Pin the version, and a digest for an OCI chart (`helm install` accepts a chart by digest since Helm 4), then verify a signature: `helm package --sign` and `helm install --verify` for a provenance file, or cosign for an OCI artifact
What will it create?                | `helm template`, `helm pull --untar`: roles, hooks, privileged Pods, host paths, other namespaces
Which images does it run?           | List them in the rendered YAML, pin their digests, and scan them with Trivy
Is the chart itself safe?           | `trivy config` and kube-linter on the rendered YAML, in the pipeline of the repository
What if it disappears?              | Mirror the chart and its images in a registry of the team, as the course on application catalogs does

- **Never** run a chart from a pull request, a gist or a blog without reading it, since an install is code execution in the cluster.

- **A new version is a new review**: the diff between two renders, and the new images.

- References: [Helm provenance](https://helm.sh/docs/topics/provenance/), [Helm best practices](https://helm.sh/docs/chart_best_practices/).

---

## Where it fits

- **Helm packages**, Git versions, and a reconciler (Argo CD, Flux, Fleet) applies: the chart, its version and its values file are what the repository holds.

- **Kustomize patches** what a chart does not let the user set, and the two are combined by the reconcilers.

- **An application catalog** of the company is a repository of charts, which this course showed how to host.

---

## Natural next steps

Need                                        | Next
--------------------------------------------|--------------------------------------------------------------------------------------
A reconciler that renders charts, with a UI | **Argo CD**: applications, sync status, Helm values
A reconciler built as a toolkit             | **Flux**: `HelmRepository` and `HelmRelease` as resources of the cluster
Charts for many clusters                    | **Rancher**, with Fleet
What the cluster does                       | **Observability**: the charts of Prometheus and Grafana are the first ones to install

- Reference: [Helm documentation](https://helm.sh/docs/), [Artifact Hub](https://artifacthub.io/), [chart-releaser](https://github.com/helm/chart-releaser-action), [chart-testing](https://github.com/helm/chart-testing-action).
