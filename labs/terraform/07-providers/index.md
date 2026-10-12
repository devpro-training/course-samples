# Providers

Terraform core is the same for every platform: what changes is the provider.
It is downloaded by `init` from a registry, and pinned by a constraint and by the lock file.

## Two providers

1. Use a second provider, `random`, and a resource that depends on it:

   ```bash exec
   mkdir -p ~/lab/providers && cd ~/lab/providers && \
   cat > terraform.tf <<TF
   terraform {
     required_version = ">= 1.16"

     required_providers {
       local = {
         source  = "hashicorp/local"
         version = "= ${LOCAL_PROVIDER_OLD_VERSION}"
       }
       random = {
         source  = "hashicorp/random"
         version = "${RANDOM_PROVIDER_VERSION}"
       }
     }
   }
   TF
   cat > main.tf <<'TF'
   resource "random_pet" "site" {
     length = 2
   }

   resource "local_file" "greeting" {
     filename = "env/${random_pet.site.id}.txt"
     content  = format("Hello from %s\n", random_pet.site.id)
   }
   TF
   ```

   [Open main.tf](:open:providers/main.tf)

   `random_pet.site.id` is a reference: the file needs the name that the pet resource makes, so Terraform creates the pet first.

2. Install them, and list what the configuration requires:

   <!-- verify: requires=network timeout=180 expect="provider[registry.terraform.io/hashicorp/random]" -->

   ```bash exec
   cd ~/lab/providers && \
   terraform init > /dev/null && \
   terraform providers
   ```

3. Apply it, and read the dependency graph: the file points to the pet.

   <!-- verify: expect="local_file.greeting" -->

   ```bash exec
   cd ~/lab/providers && \
   terraform apply -auto-approve > /dev/null && \
   terraform graph | grep -- '->' && \
   ls env
   ```

   The name does not change on the next apply, since the pet is in the state.

## The lock file

1. The lock file holds the version that was installed:

   <!-- verify: expect="2.5.3" -->

   ```bash exec
   cd ~/lab/providers && \
   grep -A2 'hashicorp/local' .terraform.lock.hcl
   ```

2. Relax the constraint: any `2.x` from `2.5`.
   `init` keeps the locked version, even though a newer one exists:

   <!-- verify: expect="Reusing previous version of hashicorp/local" -->

   ```bash exec
   cd ~/lab/providers && \
   sed -i 's/= 2.5.3/~> 2.5/' terraform.tf && \
   terraform init
   ```

3. Upgrading is a decision, taken with `-upgrade`, and the change of the lock file is reviewed with the code:

   <!-- verify: requires=network timeout=180 expect="Installed hashicorp/local v2.9" -->

   ```bash exec
   cd ~/lab/providers && \
   terraform init -upgrade
   ```

## The providers to know

The registry lists them in tiers: **Official** (owned by HashiCorp), **Partner Premier** and **Partner** (written and maintained by the vendor, which joined the partner program), **Community** (a person or a group) and **Archived** (no longer maintained).
The Terraform [documentation](https://developer.hashicorp.com/terraform/registry/providers) describes them.

Provider                      | Tier      | What it manages
------------------------------|-----------|---------------------------------------------------
`hashicorp/aws`               | Official  | Amazon Web Services
`hashicorp/azurerm`           | Official  | Microsoft Azure
`hashicorp/google`            | Official  | Google Cloud
`hashicorp/kubernetes`        | Official  | the objects of a Kubernetes cluster
`hashicorp/helm`              | Official  | Helm releases on a cluster
`integrations/github`         | Partner   | repositories, teams and settings of GitHub
`cloudflare/cloudflare`       | Partner   | DNS and the services of Cloudflare
`rancher/rancher2`            | Partner   | Rancher, its clusters and its projects
`kreuzwerker/docker`          | Community | images and containers of a Docker daemon
`hashicorp/random`            | Official  | random values, for names and passwords
`hashicorp/local`             | Official  | files on the disk, used by this lab

> The tier is read in the registry (`registry.terraform.io/v1/providers/<namespace>/<type>`), and it can change.
> A provider is a dependency that holds the credentials of an account: its tier says who maintains it, not that it is safe.

A provider block shows how the same tool reaches another platform, here only read:

```bash exec
cd ~/lab/providers && \
cat > providers.tf.example <<'TF'
provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "github" {
  owner = "devpro"
}
TF
```

[Open providers.tf.example](:open:providers/providers.tf.example)

Credentials stay out of the files: each provider reads them from the environment or from the tools of its platform.
