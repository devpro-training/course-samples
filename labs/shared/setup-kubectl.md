## kubectl

`kubectl` is the command line of Kubernetes.
k3d creates clusters and does not carry it, so it is a binary of its own, which Kubernetes publishes with its checksum.

1. Download the binary and its checksum, check it, and install it:

   <!-- verify: requires=network timeout=120 expect="kubectl: OK" -->

   ```bash exec target=docker
   cd ~/lab && \
   wget -q "${KUBECTL_URL}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" "${KUBECTL_URL}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" && \
   echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check && \
   install -m 0755 kubectl /usr/local/bin/kubectl
   ```

2. Check the version of the client.
   The cluster is not there yet:

   <!-- verify: expect="Client Version: v1." -->

   ```bash exec target=docker
   kubectl version --client
   ```
