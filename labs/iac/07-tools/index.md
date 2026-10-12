# Tools

The environment of the previous steps, written for two real tools.
Both run in the next courses: here the files are only read, and compared with `infra.json`.

## Terraform

1. Write the two files as `local_file` resources, from the `hashicorp/local` provider:

   ```bash exec
   mkdir -p ~/lab/tools && cd ~/lab/tools && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename        = "${path.module}/env/app.conf"
     content         = "port=9090\n"
     file_permission = "0640"
   }

   resource "local_file" "index" {
     filename        = "${path.module}/env/index.html"
     content         = "<h1>Hello</h1>\n"
     file_permission = "0644"
   }
   TF
   ```

   [Open main.tf](:open:tools/main.tf)

   The fields are the ones of `infra.json`: `filename` is `path`, and `file_permission` is `mode`.
   `terraform plan` lists the changes, `terraform apply` makes them, and the state file records the resources.

## Ansible

1. Write the same intent as the tasks of a playbook, with the `ansible.builtin.copy` module:

   ```bash exec
   cd ~/lab/tools && \
   cat > playbook.yml <<'YML'
   - name: Configure the web server
     hosts: web
     tasks:
       - name: Install the configuration
         ansible.builtin.copy:
           content: "port=9090\n"
           dest: /srv/env/app.conf
           mode: "0640"

       - name: Install the page
         ansible.builtin.copy:
           content: "<h1>Hello</h1>\n"
           dest: /srv/env/index.html
           mode: "0644"
   YML
   ```

   [Open playbook.yml](:open:tools/playbook.yml)

   Ansible keeps no state file: each task looks at the machine, and reports `ok` or `changed`.
   `ansible-playbook --check --diff` is its plan, and a module that does not support check mode "reports nothing and does nothing".

## The same workflow

Idea                   | This lab                  | Terraform and OpenTofu          | Ansible
-----------------------|---------------------------|---------------------------------|----------------------------
The code               | `infra.json`              | `*.tf`                          | a playbook
See the changes        | `reconcile.py plan`       | `terraform plan`                | `ansible-playbook --check --diff`
Make them              | `reconcile.py apply`      | `terraform apply`               | `ansible-playbook`
What is remembered     | `.state.json`             | the state file                  | nothing: the host is read
Drift                  | the plan lists it         | `plan -refresh-only`            | the next run reports `changed`

1. Count the lines of the two files:

   <!-- verify: expect="total" -->

   ```bash exec
   cd ~/lab/tools && \
   wc -l main.tf playbook.yml
   ```

   Terraform is stronger at creating and destroying resources of a cloud, Ansible at configuring what runs on a machine.
   The two are often combined: one creates the machine, the other configures it.
