# Setup

Docker Engine is installed in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Docker Engine is the daemon and the command line that run containers, on Linux.
Windows and macOS run it in a Linux virtual machine, which Docker Desktop manages.

System         | Install
---------------|--------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/)
Debian         | Docker Engine from Docker's apt repository, as in this step
Ubuntu, Fedora | [docs.docker.com/engine/install](https://docs.docker.com/engine/install/)

<!-- include: ../../shared/setup-docker.md -->
