# Regions and prices

A resource lives in a region, and the same SKU does not cost the same everywhere.
Microsoft publishes its public prices in an API that needs no account, the Azure Retail Prices API.

## A price list

1. Ask for the price of one virtual machine size in one region.
   The filter is an OData expression, which `jq` encodes for the URL:

   <!-- verify: requires=network timeout=60 expect="Hour" -->

   ```bash exec
   cd ~/lab && \
   FILTER="serviceName eq 'Virtual Machines' and armSkuName eq '${VM_SKU}' and armRegionName eq 'westeurope' and priceType eq 'Consumption'" && \
   wget -qO- "${PRICES_URL}?%24filter=$(jq -rn --arg f "${FILTER}" '$f|@uri')" | \
   jq -r '.Items[] | select(.productName | test("Windows") | not) | "\(.skuName): \(.retailPrice) \(.currencyCode) per \(.unitOfMeasure)"'
   ```

   `armSkuName` is the name of the size, `armRegionName` the region, and `priceType` is `Consumption` for the pay-as-you-go price.
   The Windows price includes the license, so the line of a Linux virtual machine is kept.

## The same size in three regions

1. Loop over regions, and print one line each:

   <!-- verify: requires=network timeout=120 expect="USD" -->

   ```bash exec
   cd ~/lab && \
   for region in westeurope northeurope francecentral; do
     FILTER="serviceName eq 'Virtual Machines' and armSkuName eq '${VM_SKU}' and armRegionName eq '${region}' and priceType eq 'Consumption'"
     wget -qO- "${PRICES_URL}?%24filter=$(jq -rn --arg f "${FILTER}" '$f|@uri')" | \
     jq -r '.Items[] | select(.productName | test("Windows") | not) | "\(.armRegionName): \(.retailPrice) \(.currencyCode)"'
   done
   ```

   The price depends on the region, and so do the services that exist there and the distance to the users.
   The data of a resource stays in the region it is created in, unless a feature copies it elsewhere, which is why compliance rules start with the choice of a region.

## Regions as Azure names them

A region is a set of datacenters in a perimeter with a low latency network.
A name such as `westeurope` is what a template, `--location` or `location =` expects.
The list of the regions of a subscription comes from Resource Manager:

```bash
az account list-locations --query "[].{name:name, display:displayName}" -o table
```

It needs a signed-in account, since the list depends on the subscription.
An availability zone is a group of one or more datacenters of a region, with independent power, cooling and networking, and a resource is zone-redundant when the service spreads it over several of them.
