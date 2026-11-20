## crane

[crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane) talks to a registry directly: it lists tags, reads manifests and copies images, with no container engine.

1. Download the archive and the checksums of the release, check it, and install the binary:

   <!-- verify: requires=network timeout=120 expect="go-containerregistry_Linux_x86_64.tar.gz: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" \
     "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/checksums.txt" && \
   sha256sum --check --ignore-missing checksums.txt && \
   tar -xzf go-containerregistry_Linux_x86_64.tar.gz -C ~/.local/bin crane && \
   rm go-containerregistry_Linux_x86_64.tar.gz checksums.txt
   ```

2. Check the version:

   <!-- verify: expect="0." -->

   ```bash exec
   crane version
   ```
