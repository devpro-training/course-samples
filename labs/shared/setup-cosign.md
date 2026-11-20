## cosign

[cosign](https://docs.sigstore.dev/cosign/) is the Sigstore tool that signs and verifies images and the documents attached to them.

1. Download the binary and the checksums of the release, check it, and install it:

   <!-- verify: requires=network timeout=300 expect="cosign-linux-amd64: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64" \
     "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_checksums.txt" && \
   sha256sum --check --ignore-missing cosign_checksums.txt && \
   install -m 0755 cosign-linux-amd64 ~/.local/bin/cosign && \
   rm cosign-linux-amd64 cosign_checksums.txt
   ```

2. Check the version:

   <!-- verify: expect="GitVersion:" -->

   ```bash exec
   cosign version 2>&1 | grep GitVersion
   ```
