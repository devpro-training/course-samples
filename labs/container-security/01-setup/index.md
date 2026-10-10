# Setup

Docker Engine is installed in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Every option of this lab is one of Docker Engine, and the same ideas apply to Podman, containerd and Kubernetes.
The lab runs commands that are meant to be dangerous, such as giving a container the control of the machine, so a disposable machine is the right place for them.

System         | Install
---------------|--------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/)
Debian         | Docker Engine from Docker's apt repository, as in this step
Ubuntu, Fedora | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/)

<!-- include: ../../shared/setup-docker.md -->

## A tool to read capabilities

A process holds its capabilities as a hexadecimal mask, which `capsh` turns into names.

1. Install it, with the package that provides it on Debian:

   <!-- verify: requires=network timeout=120 expect="cap_chown" -->

   ```bash exec target=docker
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get install -y -qq libcap2-bin="${LIBCAP_VERSION}" > /dev/null 2>&1 ; \
   capsh --decode=1
   ```
