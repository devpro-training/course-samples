# Summary

---

## Cheat sheet

Command / idea                                          | Means
--------------------------------------------------------|--------------------------------------------------------
`az login`, `az account show`                           | sign in, then the current subscription and tenant
`az account set --subscription <id or name>`            | the subscription that commands act on
`az <group> <command> --help`                           | the arguments of any command
`--query "<JMESPath>" -o table`                         | filter and format the JSON output
`az rest --url <ARM URL>`                               | a raw call to Resource Manager, with the token
`--debug`                                               | the HTTP requests behind a command
`az group create`, `az group delete`                    | a resource group, and everything in it
`bicep build <file>.bicep`                              | compile to the ARM template, which checks the file
`az deployment group create` and `sub create`           | deploy a template to a resource group or a subscription
`az deployment sub what-if`                             | the changes a template would make
`terraform init`, `validate`, `plan`, `apply`           | the same cycle, with the `azurerm` provider
`ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, `ARM_TENANT_ID` | the identity of a pipeline for Terraform

---

## Good practices

- **Know the scope**: tenant, management group, subscription, resource group, resource, and give each environment its own subscription.
- **Everything through Resource Manager**: a change made in the portal is a change that no file records.
- **Files over clicks**: Bicep or Terraform, in Git, reviewed, with `what-if` or `plan` before the change.
- **Identities, not secrets**: managed identities on Azure, OpenID Connect from a pipeline, a service principal as the last resort.
- **A person signs in with multifactor authentication**, an automation never uses a person.
- **Least privilege**: an Azure role at the smallest scope that works, and policy to forbid what must never exist (regions, public access).
- **Tags and names**: an owner, an environment and a cost center on every resource, and a naming scheme.
- **Region by decision**: data location, price, services available and distance to the users, and zones for what must survive a datacenter.
- **Budgets and alerts** on every subscription, and a resource group deleted when its work is done.

---

## Further reading

- [What is Azure Resource Manager?](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview) and [Azure fundamental concepts](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/fundamental-concepts).
- [Associate a subscription with a Microsoft Entra tenant](https://learn.microsoft.com/en-us/entra/fundamentals/how-subscriptions-associated-directory) and [What is Microsoft Entra?](https://learn.microsoft.com/en-us/entra/fundamentals/what-is-entra).
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) and [how to sign in](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).
- [What is Bicep?](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) and the [what-if operation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-what-if).
- [The AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) and its [authentication options](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).
- [Availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview) and the [global infrastructure](https://azure.microsoft.com/en-us/explore/global-infrastructure).
- [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite) and the [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices).
- [Azure free account](https://azure.microsoft.com/en-us/free/).

---

## Next

- Kubernetes: the container orchestrator, which Azure offers as AKS and which the next courses run locally.
