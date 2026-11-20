# Setup

A Kubernetes cluster is started in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

k3s runs on Linux, as a single binary.
Windows and macOS run it in a Linux virtual machine, as Docker Desktop does for Docker.

System         | Install
---------------|----------------------------------------------------------------------------------------------------------------
Linux          | The binary of the release, as in this step, or the script of the [quick start](https://docs.k3s.io/quick-start)
Windows, macOS | A Linux virtual machine, then the same steps

The version is the stable channel of k3s, which follows a Kubernetes minor version that is still maintained.

<!-- include: ../../shared/setup-k3s.md -->
