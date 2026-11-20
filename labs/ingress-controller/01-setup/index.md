# Setup

Docker Engine, k3d and kubectl are installed in the virtual machine that has just been created for this lab.
The cluster of the lab is a k3d cluster, which runs k3s with Traefik, its ingress controller.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

An ingress controller runs in a cluster, so any cluster does: k3d, kind, minikube, or a managed service.
This lab uses k3d, which needs Docker and nothing else.

System         | Install
---------------|------------------------------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/), then k3d with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binary of the release, or the install script
Any            | [k3d installation](https://k3d.io/stable/#installation)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->
