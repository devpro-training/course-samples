# Tenant and Resource Manager

Two services answer every request to Azure: Microsoft Entra ID says who is calling, and Azure Resource Manager (ARM) acts on the resources.
Both are public endpoints, so what they say to an anonymous caller shows the model.

## The tenant behind a domain

A tenant is a Microsoft Entra directory.
Its identifier is a GUID, and the sign-in service publishes it for any domain that has one.

1. Read the OpenID Connect configuration of a domain:

   <!-- verify: requires=network timeout=60 expect="oauth2/v2.0/token" -->

   ```bash exec
   cd ~/lab && \
   wget -qO- "https://login.microsoftonline.com/${TENANT_DOMAIN}/v2.0/.well-known/openid-configuration" | jq -r '.issuer, .token_endpoint'
   ```

   The GUID in both URLs is the tenant of the domain.
   The token endpoint is where a tool trades a proof of identity for an access token.

## Resource Manager refuses a call without a token

1. Call the API that lists the subscriptions, with no `Authorization` header:

   <!-- verify: requires=network timeout=60 expect="401 Unauthorized" -->

   ```bash exec
   cd ~/lab && \
   wget -S -O /dev/null "https://management.azure.com/subscriptions?api-version=2022-12-01" 2>&1 | grep -E "HTTP/|WWW-Authenticate"
   ```

   The answer is `401`, and its `WWW-Authenticate` header sends the caller to Microsoft Entra ID for a token.
   `management.azure.com` is the endpoint of Azure Resource Manager, the only door to the control plane, and `api-version` is required on every call.

   The portal, the CLI, Bicep, Terraform and the SDKs are all clients of this one endpoint.

## Clouds

1. The CLI knows several Azure clouds, each with its own sign-in service and Resource Manager endpoint:

   <!-- verify: expect="AzureChinaCloud" -->

   ```bash exec
   az cloud list --query "[].{name:name, signIn:endpoints.activeDirectory, resourceManager:endpoints.resourceManager}" -o table
   ```

   `AzureCloud` is the public cloud.
   The others are sovereign clouds, separate from it, such as the one of China and the one of the US government.

## No identity, no command

1. Ask the CLI who is signed in:

   <!-- verify: expect="setup account" -->

   ```bash exec
   { az account show || true; }
   ```

2. The ways to sign in are options of `az login`:

   <!-- verify: expect="--use-device-code" -->

   ```bash exec
   az login --help | grep -E "^ +--(use-device-code|service-principal|identity|federated-token)"
   ```

   Option                | Identity
   ----------------------|---------------------------------------------------------------
   `az login`            | a person, in a browser, with multifactor authentication
   `--use-device-code`   | a person, on a machine with no browser
   `--service-principal` | an application, with a secret or a certificate
   `--federated-token`   | an application, with a token from its pipeline, no secret kept
   `--identity`          | the managed identity of the Azure resource the command runs on

   The lab has no account, so none of them is run here.
   A script or a pipeline uses a service principal or a managed identity, never a person.
