# Setup

Docker Engine, k3d, kubectl, Helm and a linter are installed in the virtual machine that has just been created for this lab.
The cluster is a k3d cluster, which the next step creates.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Any cluster does: kind, minikube, k3s or a managed service.
Helm only needs a `kubeconfig` to talk to it.

System  | Install
--------|------------------------------------------------------------------------------------------------------------------
Windows | `winget install Helm.Helm`, and [Docker Desktop](https://docs.docker.com/desktop/) with k3d for a cluster
macOS   | `brew install helm`
Linux   | the release binary, as in this step, or the [install script](https://helm.sh/docs/intro/install/)
Any     | [Helm installation](https://helm.sh/docs/intro/install/), [k3d installation](https://k3d.io/stable/#installation)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->

<!-- include: ../../shared/setup-helm-machine.md -->

<!-- include: ../../shared/setup-kube-linter.md -->
