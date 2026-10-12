# OpenTofu

OpenTofu is a fork of Terraform, a Linux Foundation project.
Its documentation says it "aims to maintain compatibility with Terraform configurations".
This step runs the files and the state of the previous steps with `tofu`, and shows what differs.

<!-- include: ../../shared/setup-opentofu.md -->

## The same configuration

1. Create a configuration, apply it with Terraform, then read it with `tofu`:

   <!-- verify: requires=network timeout=180 expect="No changes" -->

   ```bash exec
   rm -rf ~/lab/tofu && \
   mkdir -p ~/lab/tofu && cd ~/lab/tofu && \
   cp ../first/terraform.tf . && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename = "env/app.conf"
     content  = "port=8080\n"
   }
   TF
   terraform init > /dev/null && \
   terraform apply -auto-approve > /dev/null && \
   rm -rf .terraform && \
   tofu init > /dev/null && \
   tofu plan
   ```

   Terraform created the file and the state, then `tofu` read both, and found the infrastructure as it is described.
   `tofu init` installed the provider again, from the OpenTofu registry.

2. The lock file was rewritten for that registry.
   OpenTofu says why in its output: the versions are kept, the hashes are not, because the providers published on the two registries are not byte for byte identical:

   <!-- verify: expect="registry.opentofu.org/hashicorp/local" -->

   ```bash exec
   cd ~/lab/tofu && \
   grep 'provider "' .terraform.lock.hcl
   ```

3. Apply a change with `tofu`, and read the version that the state records: it was `1.16.5`, written by Terraform:

   <!-- verify: expect="Apply complete! Resources: 1 added, 0 changed, 1 destroyed" -->

   ```bash exec
   cd ~/lab/tofu && \
   sed -i 's/8080/9090/' main.tf && \
   tofu apply -auto-approve
   ```

   <!-- verify: expect="terraform_version: 1.13" -->

   ```bash exec
   cd ~/lab/tofu && \
   grep terraform_version terraform.tfstate | tr -d '"'
   ```

   The field keeps the name `terraform_version`, and holds the version of the tool that wrote the state last, here OpenTofu's.

## Choosing

Question                              | Terraform                      | OpenTofu
--------------------------------------|--------------------------------|--------------------------------
Command                               | `terraform`                    | `tofu`
License                               | Business Source License 1.1    | open source, a Linux Foundation project
Registry of providers and modules     | registry.terraform.io          | registry.opentofu.org
Configuration, state, providers       | the reference                  | compatible, per its documentation

- **Migrating is a procedure, not a given.**
  The OpenTofu migration guide says: back up the state and the code, install, `tofu init`, `tofu plan` with no unexpected change, then `tofu apply`, and that an apply may update the format of the state file.

- **Compatibility is a moving target.**
  A feature of a release of one tool can be missing from the other, so the version of each is pinned and the plan is read before any apply.

- **The backend is shared.**
  The project of the previous step documents its HTTP backend for Terraform and for OpenTofu.
