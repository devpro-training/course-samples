# Course samples

Samples of courses made by [@devpro](devpro.fr) running in Sidelab.

## Courses

Course                                                   | Topic
---------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
[Git](labs/git)                                          | Install, configure, commit, clone, branch, push, pull, stash
[VS Code](labs/vscode)                                   | Workspace Trust, commands, settings, extensions, source control, debugging
[.NET](labs/dotnet)                                      | SDK and runtime, LTS and STS, console app, NuGet, xUnit tests, web app, web API
[Automated testing, the test pyramid](labs/test-pyramid) | Unit, integration and end-to-end tests of a .NET web API, and the layer that catches each bug
[GitHub](labs/github)                                    | Repository page, REST API and its rate limit, pull requests as Git references, Actions workflows
[Docker](labs/docker)                                    | Docker Engine in a virtual machine, run, images and layers, Dockerfile and cache, volumes, networks, Compose
[Linux](labs/linux)                                      | The kernel and the distributions, Red Hat and SUSE included, files, text and pipes, users, groups and permissions, why sudo, apt and dpkg, processes, systemd units
[Containers](labs/containers)                            | What a container is: `chroot`, namespaces and cgroups by hand, the OCI standards, Podman, images and registries
[Container base images](labs/base-images)                | Size, files, shell and libc of base images, SUSE BCI, Red Hat UBI, distroless, free and enterprise offers, multi-stage builds, non-root user, pinned digests
[Application catalog](labs/app-catalog)                  | Supply chain and compliance of the images and charts a team deploys: Artifact Hub, Docker Official Images, MinIO, Bitnami, SUSE Application Collection, Chainguard, signatures, SBOM, provenance, mirroring
[Kubernetes](labs/kubernetes)                            | History (Borg, Go, the CNCF), why orchestrate, cloud native patterns, what a cluster and a distribution are, managed or not, then a k3s cluster: nodes, Pods, Deployments, Services, ConfigMaps and Secrets, and the SQLite datastore
[Ingress controller](labs/ingress-controller)            | How HTTP reaches a cluster, on k3d with Traefik: why a Service is not enough, an Ingress and its controller, hosts and paths, a middleware for what the API cannot say, HTTPS and SNI, a certificate by hand, cert-manager and a private authority, then the Gateway API (gateway, routes, weights, filters), with Let's Encrypt, ngrok and cloudflared in the slides
[Helm](labs/helm)                                        | The package manager of Kubernetes, on k3d: why charts exist, a catalog (repository, search, read before installing, install, upgrade, rollback, what Helm keeps in Secrets), a first chart from plain manifests to values and templates, two releases with a values file each, quality (`helm lint`, kube-linter, a schema, `helm test`, a failed upgrade that goes back), a chart repository hosted on GitHub Pages with chart-releaser and chart-testing, an OCI registry, with Helm and GitOps and the supply chain in the slides

## Contributing

Create an issue or fork and create a Pull Request, following [CONTRIBUTING.md](CONTRIBUTING.md).
