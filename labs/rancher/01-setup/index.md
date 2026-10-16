# Setup

Docker Engine, k3d, kubectl and Helm are installed in the virtual machine `docker`, which has just been created for this lab.
Rancher will run in a k3d cluster of that machine, and a second machine, `kube`, gets a cluster of its own in a later step.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Rancher runs on any certified Kubernetes cluster, and its quick start uses one k3s node.
This lab keeps everything in two machines, with no account and no public address.

System         | Install
---------------|-----------------------------------------------------------------------------------------------------------------------------------------
Windows, macOS | [Rancher Desktop](https://rancherdesktop.io/) or Docker Desktop, then k3d, kubectl and Helm with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binaries of the releases, or k3s on the machine
Any            | [Rancher quick start](https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/helm-cli)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->

<!-- include: ../../shared/setup-helm-machine.md -->
