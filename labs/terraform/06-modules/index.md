# Modules

A module is a folder of resources used together, called with inputs, like a function.
The folder of the configuration is itself the root module.

## A module

1. Write a module that makes a site: a configuration file and a page.
   Its inputs are two variables, and its output is the folder it made:

   ```bash exec
   mkdir -p ~/lab/modules/modules/site && cd ~/lab/modules && \
   cp ../first/terraform.tf . && \
   cat > modules/site/variables.tf <<'TF'
   variable "name" {
     type        = string
     description = "Name of the site."
   }

   variable "port" {
     type        = number
     description = "Port of the site."
     default     = 8080
   }
   TF
   cat > modules/site/main.tf <<'TF'
   resource "local_file" "conf" {
     filename = "${path.root}/env/${var.name}/app.conf"
     content  = format("name=%s\nport=%d\n", var.name, var.port)
   }

   resource "local_file" "page" {
     filename = "${path.root}/env/${var.name}/index.html"
     content  = format("<h1>%s</h1>\n", var.name)
   }
   TF
   cat > modules/site/outputs.tf <<'TF'
   output "directory" {
     description = "Folder of the site."
     value       = dirname(local_file.conf.filename)
   }
   TF
   ```

   [Open modules/site/main.tf](:open:modules/modules/site/main.tf)

   A module has the same files as a root module: variables, resources, outputs.
   Nothing in it says dev or prod.

## Call it

1. Call it once per environment, from a map: one call, two sites.
   Adding a site is adding a line to the map:

   ```bash exec
   cd ~/lab/modules && \
   cat > main.tf <<'TF'
   locals {
     sites = {
       dev  = 8080
       prod = 80
     }
   }

   module "site" {
     source   = "./modules/site"
     for_each = local.sites

     name = each.key
     port = each.value
   }
   TF
   cat > outputs.tf <<'TF'
   output "directories" {
     description = "Folder of each site."
     value       = { for name, site in module.site : name => site.directory }
   }
   TF
   ```

   [Open main.tf](:open:modules/main.tf)

2. A module is loaded by `init`, and the plan lists the resources of each instance, with the address of the module in front:

   <!-- verify: requires=network timeout=180 expect="4 to add, 0 to change, 0 to destroy" -->

   ```bash exec
   cd ~/lab/modules && \
   terraform init > /dev/null && \
   terraform plan
   ```

3. Apply it, and list the files:

   <!-- verify: expect="env/prod/index.html" -->

   ```bash exec
   cd ~/lab/modules && \
   terraform apply -auto-approve && \
   find env -type f | sort
   ```

4. Add a third site, a line in the map, and read the plan: two resources, nothing else.

   <!-- verify: expect="2 to add, 0 to change, 0 to destroy" -->

   ```bash exec
   cd ~/lab/modules && \
   sed -i 's/prod = 80/prod = 80\n    test = 8081/' main.tf && \
   terraform plan
   ```

## Good practices

- **DRY**: a repeated block becomes a module or a `for_each`, and a repeated value becomes a variable or a local.
- **KISS**: the documentation advises against a module that wraps a single resource, since it adds a layer with no new abstraction, and against deeply nested module trees: keep the tree flat.
- **A module is an interface**: few inputs with types and descriptions, outputs for what callers need, no secret inside.
- **A module for a registry or another repository** is pinned with a `version`, a local one is not, since Terraform ignores `version` for a local path.
- **Use a variable only for a value that changes** between uses, the style guide says, not for every argument.
