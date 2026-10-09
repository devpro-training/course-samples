## jq

[jq](https://jqlang.org/) reads JSON, which every registry and catalog API answers in.

1. Download the binary and the checksums of the release, check it, and install it:

   <!-- verify: requires=network timeout=120 expect="jq-linux-amd64: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" \
     "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/sha256sum.txt" && \
   sha256sum --check --ignore-missing sha256sum.txt && \
   install -m 0755 jq-linux-amd64 ~/.local/bin/jq && \
   rm jq-linux-amd64 sha256sum.txt
   ```

2. Check the version:

   <!-- verify: expect="jq-1." -->

   ```bash exec
   jq --version
   ```
