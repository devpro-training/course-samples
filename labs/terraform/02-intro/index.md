# Terraform

Terraform is the tool that turns a description of infrastructure into the infrastructure itself.
The description is in files, the changes are listed before they are made, and the result is remembered.

---

## What it is

- **A language, HCL, and a tool.**
  Terraform reads `.tf` files that declare **resources**, and works out the order to create, change or destroy them.

- **A workflow in three words.**
  HashiCorp calls it "Write, Plan, Apply".

- **Providers do the work.**
  Terraform itself knows nothing of a cloud: a **provider** is a plugin that talks to an API (a cloud, Kubernetes, GitHub, a local disk), and a resource type belongs to a provider.

- **State remembers what exists.**
  Terraform "stores bindings between objects in a remote system and resource instances" of the configuration.

---

## How it works

![Terraform reads the configuration files, installs the providers from a registry, compares the configuration with the state and the real objects to build the plan, and apply calls the provider APIs and records the result in the state](../assets/terraform-architecture-dark.svg#gh-dark-mode-only)
![Terraform reads the configuration files, installs the providers from a registry, compares the configuration with the state and the real objects to build the plan, and apply calls the provider APIs and records the result in the state](../assets/terraform-architecture.svg#gh-light-mode-only)

---

## The commands

Command                    | What it does
---------------------------|-----------------------------------------------------------
`terraform init`           | installs the providers and modules, and the backend, and writes the lock file
`terraform fmt`            | formats the files in the canonical style
`terraform validate`       | checks the syntax and the consistency, with no API call
`terraform plan`           | lists the changes: `+` create, `~` update in place, `-` destroy, `-/+` replace
`terraform apply`          | makes the changes of a plan
`terraform destroy`        | plans to destroy everything that is managed, and does it

---

## Terraform and OpenTofu

- **10 August 2023**: HashiCorp moved its future releases to the Business Source License 1.1.
  **20 September 2023**: the Linux Foundation announced OpenTofu, a fork.
  **27 February 2025**: IBM completed its acquisition of HashiCorp.

- **OpenTofu is a compatible alternative.**
  Its documentation says it "aims to maintain compatibility with Terraform configurations", and that most code works "without modification".
  The command is `tofu`, and the providers come from the OpenTofu registry.

- **In this lab**, the same configuration and the same state are used by both, and the course says what differs.

---

## In this lab

Step         | What it shows
-------------|--------------------------------------------------------------
Setup        | Terraform, verified with the key and the checksums of HashiCorp
Workflow     | init, fmt, validate, plan, apply, the lock file, a second apply that changes nothing
Variables    | inputs, validation, locals, outputs, and a secret that ends up in the state
State        | the state file, a change by hand, a replace, a destroy
Modules      | the same code used for two environments
Providers    | versions, constraints, the lock file, the providers worth knowing
Backend      | where the state lives, from a local file to the MongoDB backend of devpro
OpenTofu     | the same files and state with `tofu`
Checks       | a script that gates the code in a pipeline

> The infrastructure is a folder of files, written by the `local` provider: no account, no cloud, nothing to pay.
> The same commands apply to AWS, Azure, Kubernetes or GitHub, only the provider changes.
