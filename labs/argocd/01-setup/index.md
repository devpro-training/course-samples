# Setup

Docker Engine, k3d, kubectl, a Git server and the Argo CD command line are installed in the virtual machine that has just been created for this lab.
The clusters are k3d clusters, and the Git server is Gitea, which holds the repository Argo CD follows.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Any cluster and any Git server do: kind, minikube or a managed service, GitHub, GitLab or Forgejo.
This lab keeps everything in one machine, with no account.

System         | Install
---------------|------------------------------------------------------------------------------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/), then k3d and `argocd` with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binaries of the releases
Any            | [k3d installation](https://k3d.io/stable/#installation), [Argo CD CLI installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->

<!-- include: ../../shared/setup-gitea.md -->

<!-- include: ../../shared/setup-argocd-cli.md -->

<!-- include: ../../shared/setup-gitea-clusters.md -->
