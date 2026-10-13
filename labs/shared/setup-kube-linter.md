## kube-linter

[kube-linter](https://docs.kubelinter.io/) reads Kubernetes manifests, and the YAML that `helm template` renders from a chart, and reports what is risky or missing.
It is a single binary, and its releases publish no checksum file, so the SHA-256 of the archive is pinned in the course and compared before the install.

1. Download the archive, check it, and install the binary in the machine:

   <!-- verify: requires=network timeout=120 expect="kube-linter-linux.tar.gz: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "https://github.com/stackrox/kube-linter/releases/download/v${KUBELINTER_VERSION}/kube-linter-linux.tar.gz" && \
   echo "${KUBELINTER_SHA256}  kube-linter-linux.tar.gz" | sha256sum --check && \
   tar -xzf kube-linter-linux.tar.gz kube-linter && \
   install -m 0755 kube-linter /usr/local/bin/kube-linter && \
   rm kube-linter kube-linter-linux.tar.gz
   ```

2. Check the version:

   <!-- verify: expect="0.8" -->

   ```bash exec target=docker
   kube-linter version
   ```
