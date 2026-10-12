## OSV-Scanner

[OSV-Scanner](https://google.github.io/osv-scanner/) is the scanner of Google, built on the [OSV](https://osv.dev/) database, a single binary.

1. Download the binary and the checksums of the release, check it, and install it:

   <!-- verify: requires=network timeout=180 expect="osv-scanner_linux_amd64: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_linux_amd64" \
     "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_SHA256SUMS" && \
   sha256sum --check --ignore-missing osv-scanner_SHA256SUMS && \
   install -m 0755 osv-scanner_linux_amd64 ~/.local/bin/osv-scanner && \
   rm osv-scanner_linux_amd64 osv-scanner_SHA256SUMS
   ```

2. Check the version:

   <!-- verify: expect="osv-scanner version" -->

   ```bash exec
   osv-scanner --version | head -1
   ```
