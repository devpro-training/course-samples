## Azurite

[Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) is the open-source emulator of Azure Storage, written in JavaScript.
It runs on Node.js, and npm installs it in a folder of the home directory.

1. Install it at the pinned version, and add its programs to the `PATH`, now and for every new shell:

   <!-- verify: requires=network timeout=300 expect="azurite-blob" -->

   ```bash exec
   npm install --prefix ~/.azurite "azurite@${AZURITE_VERSION}" > /dev/null 2>&1 && \
   export PATH="$HOME/.azurite/node_modules/.bin:$PATH" && \
   echo 'export PATH="$HOME/.azurite/node_modules/.bin:$PATH"' >> ~/.bashrc && \
   ls ~/.azurite/node_modules/.bin | grep azurite
   ```
