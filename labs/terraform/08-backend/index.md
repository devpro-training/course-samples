# Backend

A backend is where the state is stored.
Until now it was the default one, `local`: a file next to the code.

## A local backend, moved

1. Apply a configuration with the default backend:

   ```bash exec
   mkdir -p ~/lab/backend && cd ~/lab/backend && \
   cp ../first/terraform.tf . && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename = "env/app.conf"
     content  = "port=8080\n"
   }
   TF
   terraform init > /dev/null && \
   terraform apply -auto-approve && \
   ls
   ```

2. Declare a `local` backend with another path.
   A backend block cannot use variables, since it is read before anything else:

   ```bash exec
   cd ~/lab/backend && \
   cat > backend.tf <<'TF'
   terraform {
     backend "local" {
       path = "state/terraform.tfstate"
     }
   }
   TF
   ```

   [Open backend.tf](:open:backend/backend.tf)

3. Changing a backend needs a new `init`, which offers to copy the state to the new place:

   <!-- verify: expect="Terraform has been successfully initialized" -->

   ```bash exec
   cd ~/lab/backend && \
   terraform init -migrate-state -force-copy && \
   ls state
   ```

4. The plan reads the state from its new place and finds nothing to do:

   <!-- verify: expect="No changes" -->

   ```bash exec
   cd ~/lab/backend && \
   terraform plan
   ```

   The old `terraform.tfstate` is still there, a copy to delete once the migration is checked.

## The MongoDB backend

A team needs a state that is shared, locked while a run is in progress, and out of the repository.
Terraform's `http` backend stores it through a REST API: it reads with `GET`, writes with `POST`, deletes with `DELETE`, and locks with the requests of `lock_address` and `unlock_address`.
If the lock is held, the endpoint answers `423 Locked` or `409 Conflict`.

[terraform-backend-mongodb](https://github.com/devpro/terraform-backend-mongodb) is an HTTP backend for Terraform and OpenTofu that stores the state in MongoDB.
Its documentation lists locking, an isolation per workspace (tenant), optional encryption, a record of each update, and a container image.
It is released under the AGPL-3.0 license.

1. Write the backend block, with the addresses of the project's [usage page](https://tfbackend-mongodb.devpro.fr/usage/): the tenant `acme` and the project `demo` are examples.
   The block is checked here and not run, since the backend needs a MongoDB and a container engine:

   ```bash exec
   mkdir -p ~/lab/backend/mongodb && cd ~/lab/backend/mongodb && \
   cp ../terraform.tf . && \
   cat > backend.tf <<'TF'
   terraform {
     backend "http" {
       address        = "http://tfbackend.example.com/acme/state/demo"
       lock_address   = "http://tfbackend.example.com/acme/state/demo/lock"
       lock_method    = "POST"
       unlock_address = "http://tfbackend.example.com/acme/state/demo/lock"
       unlock_method  = "DELETE"
     }
   }
   TF
   ```

   [Open backend.tf](:open:backend/mongodb/backend.tf)

2. `init -backend=false` skips the backend, and `validate` checks that the block is well formed:

   <!-- verify: expect="configuration is valid" -->

   ```bash exec
   cd ~/lab/backend/mongodb && \
   terraform init -backend=false > /dev/null && \
   terraform validate
   ```

   With a backend running, the credentials of the tenant are given through `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`.
   Terraform's documentation recommends the environment, since a value in the file or given with `-backend-config` is written to the `.terraform` folder and to the plan files.

> Other backends do the same job: an object store with locking, HCP Terraform, a database.
> The choice depends on where the team already runs, and on who must not be able to read the state.
