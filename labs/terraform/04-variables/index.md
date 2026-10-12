# Variables

A configuration that is used for several environments does not repeat itself: its inputs are variables, its intermediate values are locals, and its results are outputs.

## Inputs

1. Declare three variables, each with a type and a description.
   One has a validation, and one is a secret and has no default:

   ```bash exec
   mkdir -p ~/lab/variables && cd ~/lab/variables && \
   cp ../first/terraform.tf . && \
   cat > variables.tf <<'TF'
   variable "environment" {
     type        = string
     description = "Name of the environment."
     default     = "dev"

     validation {
       condition     = contains(["dev", "prod"], var.environment)
       error_message = "The environment is dev or prod."
     }
   }

   variable "port" {
     type        = number
     description = "Port the application listens on."
     default     = 8080
   }

   variable "api_token" {
     type        = string
     description = "Token of the application."
     sensitive   = true
   }
   TF
   ```

   [Open variables.tf](:open:variables/variables.tf)

2. Use them in a resource, with a local value for what is computed once:

   ```bash exec
   cd ~/lab/variables && \
   cat > main.tf <<'TF'
   locals {
     directory = "env/${var.environment}"
   }

   resource "local_file" "app_conf" {
     filename = "${local.directory}/app.conf"
     content  = format("port=%d\ntoken=%s\n", var.port, var.api_token)
   }
   TF
   ```

   [Open main.tf](:open:variables/main.tf)

3. Declare two outputs, one of them marked sensitive:

   ```bash exec
   cd ~/lab/variables && \
   cat > outputs.tf <<'TF'
   output "conf_path" {
     description = "Path of the configuration file."
     value       = local_file.app_conf.filename
   }

   output "conf_content" {
     description = "The configuration, as the application reads it."
     value       = local_file.app_conf.content
     sensitive   = true
   }
   TF
   terraform init > /dev/null
   ```

   [Open outputs.tf](:open:variables/outputs.tf)

## Give the values

A value comes from the command line (`-var`), from a file (`-var-file`, or `terraform.tfvars`), from the environment (`TF_VAR_<name>`), or from the default.

1. A variable with no default and no value is an error, since a script cannot answer the question:

   <!-- verify: expect="No value for required variable" -->

   ```bash exec
   cd ~/lab/variables && \
   { terraform plan -input=false || true; }
   ```

2. A value that the validation refuses never reaches a plan:

   <!-- verify: expect="The environment is dev or prod" -->

   ```bash exec
   cd ~/lab/variables && \
   { TF_VAR_api_token=abc terraform plan -input=false -var environment=staging || true; }
   ```

3. A secret is given through the environment, so that it is in no file of the repository:

   <!-- verify: expect="conf_content = (sensitive value)" -->

   ```bash exec
   cd ~/lab/variables && \
   export TF_VAR_api_token=s3cr3t-token && \
   terraform apply -auto-approve -var port=9090
   ```

   The plan hides the content, since it is built from a sensitive value.

4. Read the outputs.
   A sensitive output is hidden, unless it is asked for by name:

   <!-- verify: expect="conf_content = <sensitive>" -->

   ```bash exec
   cd ~/lab/variables && \
   terraform output && \
   terraform output -raw conf_content
   ```

## The secret is in the state

Hiding a value from the screen is not protecting it.

1. Search the state file for the token:

   <!-- verify: expect="token=s3cr3t-token" -->

   ```bash exec
   cd ~/lab/variables && \
   grep -n "s3cr3t" terraform.tfstate
   ```

   Terraform stores it in clear text, in the state and in the plan files.
   Its documentation says anyone who can read them can read the secret, so the state is kept in a place with access control, never in the repository.
