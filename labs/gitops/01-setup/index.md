# Setup

Docker Engine, k3d, kubectl and a Git server are installed in the virtual machine that has just been created for this lab.
The cluster is a k3d cluster, and the Git server is Gitea, which holds the repository the cluster follows.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Any cluster and any Git server do: kind, minikube or a managed service, GitHub, GitLab or Forgejo.
This lab keeps everything in one machine, with no account.

System         | Install
---------------|------------------------------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/), then k3d with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binary of the release, or the install script
Any            | [k3d installation](https://k3d.io/stable/#installation), [Gitea installation](https://docs.gitea.com/installation/install-from-binary)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->

<!-- include: ../../shared/setup-gitea.md -->
