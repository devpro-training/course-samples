## The machine

A cluster runs containers, which share the kernel of the machine, and starts its components as root with cgroups.
The lab image gives neither, and this lab declares a virtual machine of its own instead (`runtime: vm` in `lab.yaml`): a Debian 12 userland, with its own kernel, and a shell that is `root` already.
The terminal of this lab is that machine.

1. Check the system, the user and the resources:

   <!-- verify: expect="Debian GNU/Linux 12" -->

   ```bash exec target=kube
   . /etc/os-release && echo "${PRETTY_NAME}" && uname -r && id -un && nproc && free -m | grep Mem
   ```

## Versions

Every version and URL of this lab is a variable declared under `env:` in `lab.yaml`, so every shell of this machine has them.
They are the ones to change to follow a newer release.

1. Check that they arrived:

   <!-- verify: expect="k3s v1." -->

   ```bash exec target=kube
   echo "k3s ${K3S_VERSION}"
   ```

## The k3s binary

[k3s](https://docs.k3s.io/) is a Kubernetes distribution delivered as a single binary.
Each release publishes the checksum of its binaries, so the download is compared with it before it is installed.

1. Download the binary and the list of checksums, check it, and install it.
   The `+` of the version is written `%2B` in a URL:

   <!-- verify: requires=network timeout=240 expect="k3s: OK" -->

   ```bash exec target=kube
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${K3S_RELEASE_URL}/${K3S_VERSION/+/%2B}/k3s" "${K3S_RELEASE_URL}/${K3S_VERSION/+/%2B}/sha256sum-amd64.txt" && \
   grep -E " k3s$" sha256sum-amd64.txt | sha256sum --check && \
   install -m 0755 k3s /usr/local/bin/k3s
   ```

2. Check the version, and the size of the file.
   The binary holds the Kubernetes components, the container runtime and the tools around them:

   <!-- verify: expect="k3s version v1." -->

   ```bash exec target=kube
   k3s --version && ls -lh /usr/local/bin/k3s
   ```

3. `kubectl` is the command line of Kubernetes, and `k3s` carries it: a link with the name of the program runs it.

   <!-- verify: expect="Client Version: v1." -->

   ```bash exec target=kube
   ln -s k3s /usr/local/bin/kubectl && kubectl version --client
   ```

## The server

`k3s server` starts the control plane and, on the same machine, a node that runs the workloads.
The machine runs no init system, so the server is started in the background, and the next command waits until the node is ready.

1. Start the server:

   ```bash exec target=kube
   nohup k3s server > /var/log/k3s.log 2>&1 &
   ```

2. Wait for the node.
   The first start unpacks the components and pulls the images of the system Pods, which takes about a minute:

   <!-- verify: timeout=240 expect="k3s1" -->

   ```bash exec target=kube
   for i in $(seq 1 120); do kubectl get nodes 2> /dev/null | grep -q " Ready.*control-plane" && break; sleep 2; done; \
   kubectl get nodes
   ```

3. `kubectl` reads the address of the API and its credentials from a kubeconfig file, `~/.kube/config` by default.
   The server wrote one in `/etc/rancher/k3s/`, and a copy makes it the default of this machine:

   <!-- verify: expect="server: https://127.0.0.1:6443" -->

   ```bash exec target=kube
   mkdir -p ~/.kube && cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && \
   grep "server:" ~/.kube/config
   ```

> [!NOTE]
> The editor of the lab shows the files of the lab container, not of this machine, so the files of this course are written by the commands, which show their content.
