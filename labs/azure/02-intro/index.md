# Azure

Azure is the cloud of Microsoft: computers, storage, networks and services that are rented by the hour and managed through an API.
Everything is created, changed and deleted by calls to that API, whichever tool sends them.

---

## What it is

- **Microsoft's public cloud.**
  It was launched in 2010 as Windows Azure, and renamed Microsoft Azure in 2014.

- **Datacenters around the world.**
  Microsoft's page on its global infrastructure states "80+ Azure regions" and "500+ datacenters", with no date, checked on 12 October 2026.
  A region is a set of datacenters in a perimeter with a low latency network, such as `westeurope` or `francecentral`.

- **One of the big three.**
  The share of the worldwide cloud infrastructure services spending in the second quarter of 2026, according to Synergy Research (release of 30 July 2026, a market of $143.4 billion):

  Provider                | Share
  ------------------------|------
  Amazon Web Services     | 28%
  Microsoft Azure         | 20%
  Google Cloud            | 15%

  Another firm, with another definition of the market, gives other figures.

- **A free account to learn.**
  The Azure free account page states a $200 credit for 30 days, then free amounts of some services, and a switch to pay-as-you-go to continue.

---

## How it works

![Five kinds of clients, the portal, the CLI, Bicep and ARM templates, Terraform and the SDKs, all ask Microsoft Entra ID for a token, then call Azure Resource Manager at management.azure.com. It authenticates and authorizes the call, then forwards it to a resource provider such as Microsoft.Storage, which creates the resource in a region. An application reaches the resource itself on the data plane](../assets/azure-request-dark.svg#gh-dark-mode-only)
![Five kinds of clients, the portal, the CLI, Bicep and ARM templates, Terraform and the SDKs, all ask Microsoft Entra ID for a token, then call Azure Resource Manager at management.azure.com. It authenticates and authorizes the call, then forwards it to a resource provider such as Microsoft.Storage, which creates the resource in a region. An application reaches the resource itself on the data plane](../assets/azure-request.svg#gh-light-mode-only)

---

## The key element: Azure Resource Manager

- **ARM is the deployment and management service of Azure.**
  Microsoft's documentation: "When you send a request through any of the Azure APIs, tools, or SDKs, Resource Manager receives the request. It authenticates and authorizes the request before forwarding it to the appropriate Azure service."

- **One API, so the same result from every tool.**
  What the portal can do, the CLI, PowerShell, REST and the SDKs can do.

- **The word has two meanings.**
  *Azure Resource Manager* is the service, and an *ARM template* is its JSON file format.
  The `azurerm` provider of Terraform is named after the service, and reads `ARM_` environment variables.
  It has nothing to do with Arm processors.

- **Control plane and data plane.**
  Resource Manager creates a storage account.
  The files inside it are read and written on the storage service, with another address and another authorization.

---

## How to interact with Azure

Way                | Use                                    | Calls ARM through
-------------------|----------------------------------------|-------------------------------------------
Azure portal       | explore, click, look at a resource     | the portal's own back end
Cloud Shell        | a shell in the browser, already signed in | the CLI or PowerShell
Azure CLI (`az`)   | scripts, one-off commands, discovery   | REST calls
Azure PowerShell   | the same, for PowerShell users         | REST calls
Bicep, ARM template | a desired state, deployed by Azure    | a deployment, run by Resource Manager
Terraform          | a desired state across providers, with a state file | the `azurerm` provider
SDKs, REST         | an application that manages resources  | HTTPS calls

- **Click in the portal to learn, write a file to keep.**
  What was clicked cannot be reviewed, repeated or reverted.
- **Bicep and Terraform are infrastructure as code.**
  Bicep is Azure only and has no state file, Terraform covers every provider and keeps a state.

---

## Terminology

Term                   | Means
-----------------------|-------------------------------------------------------------------
Tenant                 | a Microsoft Entra directory: the identities of an organization
Management group       | a container of subscriptions, to apply policy and access to many
Subscription           | the unit of billing and quotas, trusting one tenant
Resource group         | a container of resources with the same lifecycle, in one subscription
Resource               | one manageable item: a virtual machine, a storage account, a network
Resource provider      | the service that supplies a type: `Microsoft.Compute`, `Microsoft.Storage`
Region                 | where a resource runs and its data is stored: `westeurope`
Availability zone      | one or more datacenters of a region with separate power, cooling and networking
SKU                    | a size or tier of a resource, with its price: `Standard_LRS`, `Standard_B2s`
Tag                    | a name and value on a resource, for cost allocation and ownership
Policy                 | a rule that Azure evaluates on resources: allowed regions, required tags
Azure RBAC             | the permissions: a role, an identity and a scope make a role assignment

![The Microsoft Entra tenant holds the identities and is trusted by subscriptions. Below a management group, a subscription holds resource groups, and a resource group holds resources. Policy and role assignments at a scope apply to everything below it](../assets/azure-scope-dark.svg#gh-dark-mode-only)
![The Microsoft Entra tenant holds the identities and is trusted by subscriptions. Below a management group, a subscription holds resource groups, and a resource group holds resources. Policy and role assignments at a scope apply to everything below it](../assets/azure-scope.svg#gh-light-mode-only)

---

## The link with Microsoft Entra

- **Azure does not keep identities.**
  Every subscription trusts one Microsoft Entra tenant, which authenticates the callers.
  A tenant can be trusted by many subscriptions.

- **Two sets of roles.**
  Azure roles control access to Azure resources in a subscription.
  Microsoft Entra roles control the directory: users, groups and domains.

- **Four kinds of identity.**
  A user, a group, a service principal (an application) and a managed identity (an identity that Azure gives to a resource, with no secret to keep).

- **A new name.**
  Azure Active Directory became Microsoft Entra ID, announced on 11 July 2023.
  Logins, APIs and tools kept their addresses.
  Microsoft Entra is the family, Entra ID is the product that Azure uses.

- **Since September 2025, multifactor authentication is required for a person who signs in to Azure CLI.**
  Service principals and managed identities are not concerned, which is why automation uses them.

---

## In this lab

Step       | What it shows
-----------|-----------------------------------------------------------------
Setup      | Azure CLI, Bicep, Terraform, jq and Azurite, each checked and unpacked in the home directory
Tenant and Resource Manager | the tenant of a domain, the `401` of ARM, the clouds, why a command asks for `az login`
Azure CLI  | the tree of commands, `--query`, `az rest`, the HTTP behind a command
Bicep      | a storage account, compiled to the ARM template, a subscription scope with a module
Terraform  | the same account with `azurerm`, validated, and the plan that stops at Resource Manager
Regions and prices | the public price list of Azure, one size in three regions
Storage emulator | Azurite, the data plane on the local machine

> No Azure account is used, so nothing is deployed and nothing is billed.
> A command that needs an account is shown, and not run.
