# Summary

---

## Cheat sheet

Command / idea                       | Means
-------------------------------------|------------------------------------------------------------
`terraform init`                     | install providers and modules, configure the backend, write the lock file
`terraform fmt`, `validate`          | format, and check without any API call
`terraform plan`                     | the changes, nothing done: `+` create, `~` update, `-` destroy, `-/+` replace
`terraform apply`                    | make the changes; `-auto-approve` for a script
`terraform plan -refresh-only`       | report drift only
`terraform plan -detailed-exitcode`  | 0 no change, 1 error, 2 changes
`-replace=<address>`                 | destroy and create one resource again
`terraform state list`, `show`       | what is managed
`variable`, `local`, `output`        | an input, a computed value, a result
`module`                             | a folder of resources, called with inputs
`.terraform.lock.hcl`                | the provider versions and checksums, committed
`tofu`                               | the OpenTofu command, same files and state

---

## Good practices

- **Read the plan** before every apply, in a review, and apply the plan that was reviewed.
- **Pin** Terraform, the providers and the modules, and commit the lock file.
- **Keep the state safe**: a remote backend with locking and access control, never in Git, since it holds secrets in clear.
- **No secret in the code**: environment variables or a secret manager, and sensitive variables and outputs.
- **DRY**: a module or a `for_each` instead of a copy, a variable for what changes.
- **KISS**: no module around a single resource, a flat tree of modules, few variables with types and descriptions.
- **Small configurations** by lifecycle and by owner, so a plan stays readable and a mistake stays small.
- **Format and validate** in the pipeline, with a gate.

---

## Further reading

- [Terraform documentation](https://developer.hashicorp.com/terraform), the [style guide](https://developer.hashicorp.com/terraform/language/style) and [module development](https://developer.hashicorp.com/terraform/language/modules/develop).
- [State](https://developer.hashicorp.com/terraform/language/state) and the [http backend](https://developer.hashicorp.com/terraform/language/backend/http).
- [The dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock).
- [OpenTofu](https://opentofu.org/docs/intro/) and its [migration guide](https://opentofu.org/docs/intro/migration/migration-guide/).
- [terraform-backend-mongodb](https://github.com/devpro/terraform-backend-mongodb): an HTTP backend with MongoDB, for Terraform and OpenTofu.
- [The Terraform registry](https://registry.terraform.io/browse/providers).

---

## Next

- Ansible: the configuration of what runs on a machine.
- Azure: the first cloud that Terraform will manage.
