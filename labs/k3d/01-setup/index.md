# Setup

Docker Engine, k3d and kubectl are installed in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

k3d needs Docker and nothing else: it starts the nodes of the cluster as containers, so it runs wherever Docker runs.

System         | Install
---------------|------------------------------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/), then k3d with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binary of the release, or the install script
Any            | [k3d installation](https://k3d.io/stable/#installation)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->
