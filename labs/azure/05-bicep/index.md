# Bicep

An ARM template is a JSON file that declares resources, and Azure Resource Manager creates what it describes.
Bicep is a language that compiles to it: the template is what Resource Manager receives, the Bicep file is what a person writes.

> [!NOTE]
> ARM means two things on Azure: the service, Azure Resource Manager, and its JSON template format, the "ARM template".
> It has nothing to do with Arm processors.

## A resource group scope

A Bicep file has a target scope: the level of the hierarchy it deploys to.
The default is a resource group, which already exists.

1. Write a file that declares a storage account:

   ```bash exec
   mkdir -p ~/lab/azure/templates && cd ~/lab/azure/templates && \
   cat > storage.bicep <<'BICEP'
   @description('Globally unique name, 3 to 24 lowercase letters and digits.')
   param storageName string
   param location string = resourceGroup().location

   resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
     name: storageName
     location: location
     sku: {
       name: 'Standard_LRS'
     }
     kind: 'StorageV2'
     properties: {
       minimumTlsVersion: 'TLS1_2'
       allowBlobPublicAccess: false
     }
   }

   output blobEndpoint string = storage.properties.primaryEndpoints.blob
   BICEP
   ```

   [Open storage.bicep](:open:azure/templates/storage.bicep)

   `Microsoft.Storage` is the resource provider, `storageAccounts` the resource type, and `2025-01-01` the version of its API.
   `Standard_LRS` is a SKU: locally redundant storage, three copies in one datacenter.
   `param` values are given at deployment, and an `output` is returned by it.

2. Compile it, which checks the file and prints nothing when it is valid:

   <!-- verify: expect="storage.json" -->

   ```bash exec
   cd ~/lab/azure/templates && \
   bicep build storage.bicep && ls
   ```

3. Read the ARM template that Resource Manager would receive:

   <!-- verify: expect="Microsoft.Storage/storageAccounts" -->

   ```bash exec
   cd ~/lab/azure/templates && \
   jq '.resources[] | {type, apiVersion, name, location, sku}' storage.json
   ```

   The `[parameters('storageName')]` text is an expression that Resource Manager evaluates when the deployment runs.

## A subscription scope

A resource group is itself a resource, created at the scope of a subscription.
A second file creates the group, then deploys the first one inside it as a module.

1. Write it:

   ```bash exec
   cd ~/lab/azure/templates && \
   cat > main.bicep <<'BICEP'
   targetScope = 'subscription'

   param location string = 'westeurope'
   param storageName string

   resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
     name: 'rg-demo'
     location: location
   }

   module storage 'storage.bicep' = {
     scope: rg
     name: 'storage'
     params: {
       storageName: storageName
     }
   }
   BICEP
   ```

   [Open main.bicep](:open:azure/templates/main.bicep)

2. Compile it, and list the types it deploys:

   <!-- verify: expect="Microsoft.Resources/deployments" -->

   ```bash exec
   cd ~/lab/azure/templates && \
   bicep build main.bicep && \
   jq -r '.resources[].type' main.json
   ```

   The module became a nested deployment, a resource of type `Microsoft.Resources/deployments`, aimed at the resource group.

3. The linter of the compiler reports bad practice, here nothing:

   <!-- verify: expect="lint status 0" -->

   ```bash exec
   cd ~/lab/azure/templates && \
   bicep lint main.bicep && echo "lint status $?"
   ```

## Deploying

A deployment needs a signed-in account, so it is only read here:

```bash
az deployment sub what-if --location westeurope --template-file main.bicep --parameters storageName=${STORAGE_NAME}
az deployment sub create  --location westeurope --template-file main.bicep --parameters storageName=${STORAGE_NAME}
```

`what-if` asks Resource Manager for the changes the template would make, and `create` makes them.
`sub` is the scope: `az deployment group` targets a resource group, `mg` a management group and `tenant` the tenant.
The deployment is incremental by default: what the template does not mention is left alone.
