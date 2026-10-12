# Storage emulator

Azure separates two planes.
The control plane, Azure Resource Manager, creates the storage account.
The data plane is the storage service itself, at `<account>.blob.core.windows.net`, where containers and blobs live.
Azurite emulates the data plane on the local machine, which makes the difference visible.

## Start the emulator

1. Start the blob service on the loopback address, in the background:

   ```bash exec
   mkdir -p ~/lab/azure/emulator && cd ~/lab/azure/emulator
   ```

   ```bash exec
   nohup azurite-blob --silent --location ~/lab/azure/emulator/data --blobHost 127.0.0.1 > azurite.log 2>&1 &
   ```

2. Wait until it listens:

   <!-- verify: timeout=60 expect="listens on" -->

   ```bash exec
   cd ~/lab/azure/emulator && \
   until grep -q "listens" azurite.log; do sleep 1; done; cat azurite.log
   ```

## The account and its key

A storage account is addressed by its name and authorized by a key, or by a token of Microsoft Entra ID.
Azurite accepts one well-known account, which is the same on every machine, so it is no secret.

1. Put the connection string in the variable the CLI reads:

   ```bash exec
   export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=${AZURITE_ACCOUNT};AccountKey=${AZURITE_KEY};BlobEndpoint=http://127.0.0.1:10000/${AZURITE_ACCOUNT};" && \
   echo "export AZURE_STORAGE_CONNECTION_STRING='${AZURE_STORAGE_CONNECTION_STRING}'" >> ~/.bashrc
   ```

   The emulator puts the account name in the path of the URL, where Azure puts it in the host name: `http://127.0.0.1:10000/<account>/` instead of `https://<account>.blob.core.windows.net/`.

## Containers and blobs

1. Create a container, and upload a file into it:

   <!-- verify: expect="lastModified" -->

   ```bash exec
   cd ~/lab/azure/emulator && \
   az storage container create --name demo --output none && \
   echo "A blob is a file in a container." > hello.txt && \
   az storage blob upload --container-name demo --file hello.txt --name hello.txt --overwrite
   ```

2. List the blobs:

   <!-- verify: expect="hello.txt" -->

   ```bash exec
   az storage blob list --container-name demo --query "[].{name:name, bytes:properties.contentLength}" -o table
   ```

## Private by default

1. Read the blob with no key, as an anonymous visitor:

   <!-- verify: expect="AuthorizationFailure" -->

   ```bash exec
   cd ~/lab/azure/emulator && \
   wget -S -O /dev/null "http://127.0.0.1:10000/${AZURITE_ACCOUNT}/demo/hello.txt" 2>&1 | grep -E "HTTP/|x-ms-error-code"
   ```

2. Make the container public for blobs, and read it again:

   <!-- verify: expect="A blob is a file" -->

   ```bash exec
   cd ~/lab/azure/emulator && \
   az storage container set-permission --name demo --public-access blob --output none && \
   wget -qO- "http://127.0.0.1:10000/${AZURITE_ACCOUNT}/demo/hello.txt"
   ```

   On Azure, `allowBlobPublicAccess: false` on the account, as in the Bicep and Terraform files, refuses this setting for every container of the account.

## What the emulator does not have

1. Listing the storage accounts is a call to Resource Manager, which Azurite does not emulate:

   <!-- verify: expect="setup account" -->

   ```bash exec
   { az storage account list || true; }
   ```

   The account exists only as a name and a key, and no subscription, resource group, SKU or region exists around it.
   What Bicep and Terraform manage is the control plane, and what the emulator holds is the data plane.

## Stop the emulator

1. Stop it with the command line it was started with:

   ```bash exec
   pkill -f "^node .*azurite-blob" ; sleep 1; echo "emulator stopped"
   ```
