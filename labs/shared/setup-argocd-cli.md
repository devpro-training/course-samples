## Argo CD command line

`argocd` is the command line of Argo CD, a binary of its own.
Each release publishes the checksums of its binaries, so the download is compared with them before it is installed.

1. Download the binary and the list of checksums, check it, and install it:

   <!-- verify: requires=network timeout=120 expect="argocd-linux-amd64: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${ARGOCDREL_URL}/${ARGOCDREL_VERSION}/argocd-linux-amd64" "${ARGOCDREL_URL}/${ARGOCDREL_VERSION}/cli_checksums.txt" && \
   grep " argocd-linux-amd64$" cli_checksums.txt | sha256sum --check && \
   install -m 0755 argocd-linux-amd64 /usr/local/bin/argocd
   ```

2. Check the version of the client.
   The server is not there yet:

   <!-- verify: expect="argocd: v3." -->

   ```bash exec target=docker
   argocd version --client --short
   ```
