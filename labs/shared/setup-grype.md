## Grype

[Grype](https://github.com/anchore/grype) is the vulnerability scanner of Anchore, a single binary.

1. Download the archive and the checksums of the release, check it, and install the binary:

   <!-- verify: requires=network timeout=180 expect="_linux_amd64.tar.gz: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz" \
     "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_checksums.txt" && \
   sha256sum --check --ignore-missing "grype_${GRYPE_VERSION}_checksums.txt" && \
   tar -xzf "grype_${GRYPE_VERSION}_linux_amd64.tar.gz" -C ~/.local/bin grype && \
   rm "grype_${GRYPE_VERSION}_linux_amd64.tar.gz" "grype_${GRYPE_VERSION}_checksums.txt"
   ```

2. Check the version:

   <!-- verify: expect="Version:" -->

   ```bash exec
   grype version | grep -m1 Version
   ```
