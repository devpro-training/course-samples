# Terraform

Terraform describes the same resource with its own language, and the `azurerm` provider turns it into calls to Azure Resource Manager.
The name is the abbreviation: `azurerm` is Azure Resource Manager.

## The same storage account

1. Write the configuration, with the provider pinned at a version:

   ```bash exec
   mkdir -p ~/lab/azure/terraform && cd ~/lab/azure/terraform && \
   cat > main.tf <<TF
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "${AZURERM_VERSION}"
       }
     }
   }

   provider "azurerm" {
     features {}
   }

   variable "storage_name" {
     type = string
   }

   resource "azurerm_resource_group" "demo" {
     name     = "rg-demo"
     location = "westeurope"
   }

   resource "azurerm_storage_account" "demo" {
     name                            = var.storage_name
     resource_group_name             = azurerm_resource_group.demo.name
     location                        = azurerm_resource_group.demo.location
     account_tier                    = "Standard"
     account_replication_type        = "LRS"
     min_tls_version                 = "TLS1_2"
     allow_nested_items_to_be_public = false
   }
   TF
   ```

   [Open main.tf](:open:azure/terraform/main.tf)

   `account_tier` and `account_replication_type` together are the SKU `Standard_LRS` of the Bicep file.
   The resource group is a resource of its own, and the storage account refers to it, which gives Terraform the order to create them in.

2. Download the provider, a program of a few hundred MB:

   <!-- verify: requires=network timeout=300 expect="Terraform has been successfully initialized" -->

   ```bash exec
   cd ~/lab/azure/terraform && \
   terraform init -input=false
   ```

3. Validate the configuration, which needs no account:

   <!-- verify: expect="configuration is valid" -->

   ```bash exec
   cd ~/lab/azure/terraform && \
   terraform validate
   ```

## A plan needs an identity

1. Ask for a plan.
   The provider reads the subscription from `ARM_SUBSCRIPTION_ID`, one of the `ARM_` variables it documents:

   <!-- verify: expect="Resource Manager API" -->

   ```bash exec
   cd ~/lab/azure/terraform && \
   export ARM_SUBSCRIPTION_ID="${DEMO_SUBSCRIPTION_ID}" && \
   { terraform plan -input=false -var storage_name="${STORAGE_NAME}" || true; }
   ```

   The plan stops before it reads anything: the provider has no token for Resource Manager.
   It looked for one in the Azure CLI, which is the first way to authenticate that its documentation lists, and the CLI answered `az login`.

Way to authenticate                   | For
--------------------------------------|--------------------------------------------------------
the Azure CLI                         | a person, on a workstation
a service principal and a secret      | automation, with a secret to rotate
a service principal and a certificate | automation, with a certificate to rotate
OpenID Connect                        | a pipeline, with a short-lived token and no secret kept
a managed identity                    | a machine of Azure, with no secret at all

   The `ARM_` variables (`ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_USE_OIDC`) carry the identity in a pipeline.

## Terraform or Bicep

Aspect             | Bicep                                 | Terraform
-------------------|---------------------------------------|---------------------------------------
Scope              | Azure only                            | Azure and every other provider
State              | none, Azure stores it                 | a state file, in a backend, to protect
Preview            | `what-if`                             | `plan`
New Azure features | on the day the API is published       | when the provider has them
Calls              | Resource Manager, from the deployment | Resource Manager, from the provider

Both end in the same API, so the choice is about the rest of the team's stack, not about what Azure can do.
