# Setup

A k3s server is started in the virtual machine that has just been created for this lab.
A second machine, `agent`, waits for the step that adds a node.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

k3s runs on Linux, as a single binary.
Windows and macOS run it in a Linux virtual machine, as Docker Desktop does for Docker.

System          | Install
----------------|--------------------------------------------------------------------
Linux           | The script of the [quick start](https://docs.k3s.io/quick-start), or the binary of the release, as in this step
Windows, macOS  | A Linux virtual machine, then the same steps

This lab starts with the minor version before the stable channel, so the upgrade step has something to upgrade.

<!-- include: ../../shared/setup-k3s.md -->
