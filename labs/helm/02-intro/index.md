# Helm

Helm is the package manager of Kubernetes: an application is installed, configured, upgraded and removed with a name and a version, and not with a folder of YAML files.

---

## The problem

- **An application is many files**: a Deployment, a Service, an Ingress, a ConfigMap, a ServiceAccount, and the list grows with the application.

- **The same files, with differences**: development, staging and production need another replica count, another host name, another image tag, and copying the files means fixing the same bug three times.

- **`kubectl apply` has no memory of a release**: it applies files, and does not know which version of the application is installed, or what the previous one was.

- **Installing a tool is a copy and paste**: the documentation of each project lists a URL of a YAML file, and the user cannot say which parts are settings.

- **Removing is a hunt**: the objects of an application are found one by one, and a forgotten one stays.

---

## How it works

![A chart from a catalog and the values of the user go through the template engine of helm, which applies plain YAML to the cluster and records each revision of the release in a Secret](../assets/helm-dark.svg#gh-dark-mode-only)
![A chart from a catalog and the values of the user go through the template engine of helm, which applies plain YAML to the cluster and records each revision of the release in a Secret](../assets/helm.svg#gh-light-mode-only)

---

## Four words

Word       | Meaning
-----------|-------------------------------------------------------------------------------------------------------------------------------
Chart      | A package: `Chart.yaml`, templates, default values, and optionally a schema, tests and dependencies
Values     | The settings of a chart: the defaults of the chart, then the files (`-f`) and options (`--set`) of the user, the last one wins
Release    | One installation of a chart in a cluster, with a name, and a revision number that grows with every change
Repository | A web server with an `index.yaml` and the archives of the charts, or an OCI registry, as for images

- **The same chart can be installed many times**: `dev` and `prod` are two releases of one chart.

- **Helm is a client**: it has no server in the cluster, and the history of a release is stored in Secrets of the namespace.

---

## The application store of cloud native

- **Nearly every cloud native project publishes a chart**: an ingress controller, a certificate manager, a GitOps tool, a monitoring stack, a database operator.
  Installing it takes the four commands of the first step, and the documentation of the project lists the values.

- **[Artifact Hub](https://artifacthub.io/) is the search engine**: it indexes charts, but also operators, Kyverno and Falco policies and container images, from repositories that publishers declare.

- **Two ways to publish**: a chart repository, which is a static web site (GitHub Pages is enough), and an OCI registry, such as `ghcr.io` or Docker Hub, which the last steps show.

- **A company does the same for itself**: a repository of the charts it validated, which is a catalog of its own.

- Reference: [Helm documentation](https://helm.sh/docs/), [Artifact Hub documentation](https://artifacthub.io/docs/).

---

## A chart is a recipe, not an image

- **An image is what runs, a chart is what installs it**: the rights, the volumes, the network, the number of Pods, the hooks that run before and after, and the roles it creates.

- **The chart runs with the rights of the user who types the command**, often a cluster administrator.

- **So it is read before it is trusted**: `helm template` shows what it creates, `helm pull --untar` shows its files and its hooks, and a chart is pinned to a version.

- **The supply chain has two parts here**: the chart and the images it names, and each has its own publisher, its own signature and its own update.
  The last slide of the course comes back to it.

---

## Helm and GitOps

- **A chart plus a values file is a declarative description**: the same two files always render the same YAML, which is what a Git repository can hold.

- **The reconcilers of GitOps render charts**: Argo CD and Flux read a chart and a values file from Git and run the equivalent of `helm template` and an apply, then keep the cluster equal to it.
  Their own installation is, most often, a chart.

- **Kustomize is the other half**: it patches plain YAML with overlays and needs no template.
  The two combine, a chart rendered by the reconciler and patched by an overlay, which the next courses use.

- **So Helm is the foundation of cloud native GitOps**: what the repository holds is a chart, its version and a values file, and the cluster never sees `helm install` typed by a person.

---

## Where Helm comes from

- **CNCF**: Helm was accepted at the Incubating level on 1 June 2018 and graduated on 1 May 2020.

- **Helm 4** was released on 12 November 2025 at KubeCon + CloudNativeCon, the first new major version in six years.
  It adds server-side apply for new installs, a wait based on the status of each resource, and plugins as WebAssembly, and renames `--atomic` to `--rollback-on-failure`.

- **The charts of Helm 3 still install**: chart `apiVersion: v2` is the format of this course.

- Reference: [CNCF, Helm](https://www.cncf.io/projects/helm/), [Helm 4 released](https://helm.sh/blog/helm-4-released/), [Helm 4 overview](https://helm.sh/docs/overview/).

---

## In this lab

Step              | What it shows
------------------|--------------------------------------------------------------------------------------------------------------------------------
Setup             | Docker Engine, k3d, kubectl, Helm and kube-linter, from checked binaries
Use a chart       | Add a repository, search, read before installing, install, upgrade, roll back, what Helm keeps, uninstall
Create a chart    | Plain manifests, values, templates, two releases of one chart with a file of values each, a package
Quality           | `helm lint`, kube-linter, helpers, a schema, `helm test`, an upgrade that fails and goes back
Host a repository | An index and a web server, the same commands as any catalog, the workflows of GitHub for the release and the checks, a registry

> One virtual machine and no account: the cluster is k3d, the catalog of the first step is public, and the repository of the last one is a web server of the lab.
