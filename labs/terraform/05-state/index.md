# State

The state is how Terraform knows which real objects belong to which resource of the configuration.

## The state file

1. Write two resources and apply them:

   ```bash exec
   mkdir -p ~/lab/state && cd ~/lab/state && \
   cp ../first/terraform.tf . && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename        = "env/app.conf"
     content         = "port=8080\n"
     file_permission = "0640"
   }

   resource "local_file" "index" {
     filename        = "env/index.html"
     content         = "<h1>Hello</h1>\n"
     file_permission = "0644"
   }
   TF
   terraform init > /dev/null && \
   terraform apply -auto-approve
   ```

   [Open main.tf](:open:state/main.tf)

2. The default backend writes the state to `terraform.tfstate` in the folder.
   List what it manages, and show one resource as Terraform knows it:

   <!-- verify: expect="# local_file.index:" -->

   ```bash exec
   cd ~/lab/state && \
   terraform state list && \
   terraform state show local_file.index
   ```

3. Read the file itself.
   It is JSON, the `serial` grows with each change, and its format is not a contract: the documentation says to use `terraform show -json` or `terraform output -json` in automation, not the file:

   <!-- verify: expect="terraform_version: 1.16" -->

   ```bash exec
   cd ~/lab/state && \
   grep -E '"(version|terraform_version|serial)"' terraform.tfstate | tr -d '"'
   ```

   [Open terraform.tfstate](:open:state/terraform.tfstate)

## Drift

A change made outside Terraform is drift.

1. Change the file by hand:

   ```bash exec
   cd ~/lab/state && \
   echo "port=9999" > env/app.conf
   ```

2. A refresh-only plan reports the drift and changes nothing:

   <!-- verify: expect="Objects have changed outside of Terraform" -->

   ```bash exec
   cd ~/lab/state && \
   terraform plan -refresh-only
   ```

   The provider decides how a difference shows.
   For `local_file`, a file whose content differs is reported as deleted.

3. The plan of the code proposes to bring the file back.
   `-detailed-exitcode` gives a status that a script can read: 0 for no change, 1 for an error, 2 for changes:

   <!-- verify: expect="plan status 2" -->

   ```bash exec
   cd ~/lab/state && \
   { terraform plan -input=false -detailed-exitcode > /dev/null; echo "plan status $?"; }
   ```

4. Apply it: the code wins, and the file is what the code says:

   <!-- verify: expect="port=8080" -->

   ```bash exec
   cd ~/lab/state && \
   terraform apply -auto-approve > /dev/null && \
   cat env/app.conf
   ```

## Replace and destroy

1. `-replace` forces a resource to be destroyed and created again, for an object that is unhealthy though the code did not change:

   <!-- verify: expect="1 to add, 0 to change, 1 to destroy" -->

   ```bash exec
   cd ~/lab/state && \
   terraform plan -replace=local_file.index
   ```

2. A resource removed from the code is destroyed, since the state says Terraform created it:

   <!-- verify: expect="0 to add, 0 to change, 1 to destroy" -->

   ```bash exec
   cd ~/lab/state && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename        = "env/app.conf"
     content         = "port=8080\n"
     file_permission = "0640"
   }
   TF
   terraform plan
   ```

3. Apply it, then destroy what is left.
   The state no longer lists any resource:

   <!-- verify: expect="Destroy complete! Resources: 1 destroyed" -->

   ```bash exec
   cd ~/lab/state && \
   terraform apply -auto-approve > /dev/null && \
   ls env && \
   terraform destroy -auto-approve && \
   terraform state list | wc -l
   ```
