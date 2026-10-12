# Workflow

A first configuration, and the loop of the tool: write, format, initialize, validate, plan, apply.

## Write

1. Declare the version of Terraform and of the provider, in `terraform.tf`:

   ```bash exec
   mkdir -p ~/lab/first && cd ~/lab/first && \
   cat > terraform.tf <<TF
   terraform {
     required_version = ">= 1.16"

     required_providers {
       local = {
         source  = "hashicorp/local"
         version = "${LOCAL_PROVIDER_VERSION}"
       }
     }
   }
   TF
   ```

   [Open terraform.tf](:open:first/terraform.tf)

   `hashicorp/local` is `<namespace>/<type>` on the registry.
   The version is exact, so that two runs on two machines use the same plugin.

2. Declare one resource, a file with its content and its permissions:

   ```bash exec
   cd ~/lab/first && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename        = "env/app.conf"
     content         = "port=8080\n"
     file_permission = "0640"
   }
   TF
   ```

   [Open main.tf](:open:first/main.tf)

   `local_file` is the type, `app_conf` the name: the pair, `local_file.app_conf`, is the address of the resource in a plan and in the state.

## Format, initialize, validate

1. `terraform fmt` rewrites the files in the canonical style and prints the names of those it changed, nothing here:

   <!-- verify: expect="fmt status 0" -->

   ```bash exec
   cd ~/lab/first && \
   terraform fmt -check && \
   echo "fmt status $?"
   ```

2. `terraform init` installs the provider from the registry, checks its signature, and writes the lock file:

   <!-- verify: requires=network timeout=180 expect="Terraform has been successfully initialized" -->

   ```bash exec
   cd ~/lab/first && \
   terraform init
   ```

3. `terraform validate` checks the configuration with no call to any API:

   <!-- verify: expect="configuration is valid" -->

   ```bash exec
   cd ~/lab/first && \
   terraform validate
   ```

4. Read the lock file: the exact version of the provider, the constraint it satisfies, and the checksums of its packages.
   It is committed with the code, so that a change of dependency goes through a review.

   [Open .terraform.lock.hcl](:open:first/.terraform.lock.hcl)

## Plan, apply

1. The plan changes nothing, and shows what an apply would do:

   <!-- verify: expect="1 to add, 0 to change, 0 to destroy" -->

   ```bash exec
   cd ~/lab/first && \
   terraform plan
   ```

   `+` means create.
   `(known after apply)` is a value that the provider computes, such as the checksums of the content.

2. Apply it.
   `-auto-approve` skips the question that a person answers, which a script cannot:

   <!-- verify: expect="Apply complete! Resources: 1 added" -->

   ```bash exec
   cd ~/lab/first && \
   terraform apply -auto-approve
   ```

3. The file exists, with the mode of the configuration:

   <!-- verify: expect="-rw-r----- 1 labuser" -->

   ```bash exec
   cd ~/lab/first && \
   ls -l env/ && cat env/app.conf
   ```

4. Apply again: the real infrastructure matches the configuration, so nothing changes.
   This is the idempotence of the [Infrastructure as Code](../iac) course, with the tool doing the comparison:

   <!-- verify: expect="Apply complete! Resources: 0 added, 0 changed, 0 destroyed" -->

   ```bash exec
   cd ~/lab/first && \
   terraform apply -auto-approve
   ```

## Change the code

1. Change the port, in the only place it is written:

   ```bash exec
   cd ~/lab/first && \
   sed -i 's/8080/9090/' main.tf
   ```

2. The plan is a difference of one resource, replaced because the provider cannot change the content of a file in place:

   <!-- verify: expect="forces replacement" -->

   ```bash exec
   cd ~/lab/first && \
   terraform plan
   ```

   `-/+` is a replace: destroy, then create.
   `# forces replacement` names the argument that cannot be updated in place.

3. Apply it, and read the file:

   <!-- verify: expect="Apply complete! Resources: 1 added, 0 changed, 1 destroyed" -->

   ```bash exec
   cd ~/lab/first && \
   terraform apply -auto-approve && \
   cat env/app.conf
   ```
