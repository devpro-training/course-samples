## Bicep

[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) is the language of Azure for describing resources.
Its compiler is a single binary, which turns a `.bicep` file into an ARM template.
`az bicep install` downloads the same binary, so it is taken here from the release page, and compared with the checksum that GitHub shows for the asset.

1. Download the binary, check it, and install it:

   <!-- verify: requires=network timeout=180 expect="bicep-linux-x64: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-x64" && \
   echo "${BICEP_SHA256}  bicep-linux-x64" | sha256sum --check && \
   install -m 0755 bicep-linux-x64 ~/.local/bin/bicep && \
   rm bicep-linux-x64
   ```

2. Check the version:

   <!-- verify: expect="Bicep CLI version" -->

   ```bash exec
   bicep --version
   ```
