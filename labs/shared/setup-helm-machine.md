## Helm

[Helm](https://helm.sh/) is the package manager of Kubernetes: a chart is a set of templates and default values, stored in a repository or a registry like an image.
It is a single binary, and the release publishes the checksum of its archive, so the download is compared with it before it is installed.
It reads the cluster from the same `kubeconfig` as `kubectl`.

1. Download the archive and its checksum, check it, and install the binary in the machine:

   <!-- verify: requires=network timeout=120 expect="linux-amd64.tar.gz: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
     "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
   sha256sum --check "helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
   tar -xzf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" linux-amd64/helm && \
   install -m 0755 linux-amd64/helm /usr/local/bin/helm && \
   rm -r "helm-v${HELM_VERSION}-linux-amd64.tar.gz" "helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" linux-amd64
   ```

2. Check the version:

   <!-- verify: expect="v4." -->

   ```bash exec target=docker
   helm version --short
   ```
