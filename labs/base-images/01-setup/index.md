# Setup

Docker Engine is installed in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Any tool that builds and runs OCI images does the same job, Docker Engine is used here since it is the common reference.
Podman and Buildah read a `Containerfile` as they read a `Dockerfile`, and the course Containers shows the standard behind them.

System         | Install
---------------|--------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/) or [Podman Desktop](https://podman-desktop.io/)
Debian         | Docker Engine from Docker's apt repository, as in this step
Ubuntu, Fedora | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/)

<!-- include: ../../shared/setup-docker.md -->
