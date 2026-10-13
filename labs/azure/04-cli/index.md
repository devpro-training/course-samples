# Azure CLI

`az` is a client of Azure Resource Manager: it turns a command into REST calls, with a token from `az login`.
Its commands are a tree of groups, so the tool is explored from the help.

## The tree of commands

1. List the groups of the first level:

   <!-- verify: expect="Manage Azure Cloud Storage" -->

   ```bash exec
   cd ~/lab && \
   az --help | grep -E "^ +(account|group|storage|vm|network|role|ad) "
   ```

   Group     | Manages
   ----------|------------------------------------------------
   `account` | the subscriptions and the sign-in
   `group`   | resource groups
   `storage` | storage accounts and their data
   `vm`      | virtual machines
   `network` | virtual networks and what runs on them
   `role`    | Azure role assignments, the permissions
   `ad`      | Microsoft Entra objects, users and applications

2. The help of a command lists its arguments, the required ones first:

   <!-- verify: expect="--resource-group" -->

   ```bash exec
   az storage account create --help | grep -E "^ +--(name|resource-group|location|sku|kind|min-tls-version|allow-blob-public-access)"
   ```

   The command creates a storage account in a resource group: the same fields appear in the Bicep and the Terraform of the next steps.

## Output and queries

1. The output is JSON, and `-o` changes the format.
   `--query` filters it with [JMESPath](https://jmespath.org/), before it is printed:

   <!-- verify: expect="AzureUSGovernment" -->

   ```bash exec
   az cloud list --query "[].name" -o tsv
   ```

2. The same list as a table, with chosen columns:

   <!-- verify: expect="https://portal.azure.com" -->

   ```bash exec
   az cloud list --query "[].{Name:name, Portal:endpoints.portal}" -o table
   ```

## A raw call

1. `az rest` sends a request to a Resource Manager URL, and adds the token of the signed-in account.
   Without an account, the header is skipped, which suits an endpoint that is public:

   <!-- verify: requires=network timeout=60 expect="AzureCloud" -->

   ```bash exec
   az rest --skip-authorization-header --url "https://management.azure.com/metadata/endpoints?api-version=2020-01-01" --query "[].name" -o tsv
   ```

   The endpoint lists the clouds and their service addresses.

2. `--debug` prints the HTTP request behind a command:

   <!-- verify: requires=network timeout=60 expect="Request URL" -->

   ```bash exec
   az rest --skip-authorization-header --url "https://management.azure.com/metadata/endpoints?api-version=2020-01-01" --query "[0].name" --debug 2>&1 | grep -E "Request (URL|method)"
   ```

   Every `az` command is one or several such calls, so anything the CLI does can also be done with a REST client and a token.

## Configuration

1. The settings of the CLI are files of the home directory, and environment variables with the prefix `AZURE_` override them:

   <!-- verify: expect="collect_telemetry" -->

   ```bash exec
   ls ~/.azure && az config get
   ```

   The sign-in tokens and the list of subscriptions are kept in the same folder, so it is private to the user.
