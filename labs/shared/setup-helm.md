## Helm

[Helm](https://helm.sh/) is the package manager of Kubernetes: a chart is a set of templates and default values, stored in a registry like an image.
Reading and rendering a chart needs no cluster.

1. Download the archive and its checksum, check it, and install the binary:

   <!-- verify: requires=network timeout=120 expect="linux-amd64.tar.gz: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
     "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
   sha256sum --check "helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum" && \
   tar -xzf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" -C ~/.local/bin --strip-components=1 linux-amd64/helm && \
   rm "helm-v${HELM_VERSION}-linux-amd64.tar.gz" "helm-v${HELM_VERSION}-linux-amd64.tar.gz.sha256sum"
   ```

2. Check the version:

   <!-- verify: expect="v4." -->

   ```bash exec
   helm version --short
   ```
