# Course samples

Short IT courses, each a [sidelab](https://www.npmjs.com/package/sidelab-cli) lab with slides, diagrams and a live terminal.

## Courses

Course                                | Topic
--------------------------------------|---------------------------------------------------------
[Git](labs/git) | Install, configure, commit, clone, branch, push, pull, stash
[VS Code](labs/vscode) | Workspace Trust, commands, settings, extensions, source control, debugging
[.NET](labs/dotnet) | SDK and runtime, LTS and STS, console app, NuGet, xUnit tests, web app, web API
[Automated testing, the test pyramid](labs/test-pyramid) | Unit, integration and end-to-end tests of a .NET web API, and the layer that catches each bug
[GitHub](labs/github) | Repository page, REST API and its rate limit, pull requests as Git references, Actions workflows
[CI/CD](labs/cicd) | A pipeline script, a Git hook as CI server, red and green runs, an artifact deployed and rolled back, the same pipeline as a workflow
[Playwright](labs/playwright) | Install, locators, auto-waiting assertions, a mocked API, the HTML report and the trace viewer
[Docker](labs/docker) | Docker Engine in a virtual machine, run, images and layers, Dockerfile and cache, volumes, networks, Compose
[Linux](labs/linux) | The kernel and the distributions, Red Hat and SUSE included, files, text and pipes, users, groups and permissions, why sudo, apt and dpkg, processes, systemd units
[Containers](labs/containers) | What a container is: `chroot`, namespaces and cgroups by hand, the OCI standards, Podman, images and registries
[Container base images](labs/base-images) | Size, files, shell and libc of base images, SUSE BCI, Red Hat UBI, distroless, free and enterprise offers, multi-stage builds, non-root user, pinned digests
[Application catalog](labs/app-catalog) | Supply chain and compliance of the images and charts a team deploys: Artifact Hub, Docker Official Images, MinIO, Bitnami, SUSE Application Collection, Chainguard, signatures, SBOM, provenance, mirroring

## Contributing

Courses are written and tested as described in [writing courses](docs/writing-courses.md).
