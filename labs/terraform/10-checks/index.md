# Checks

What a pipeline runs on a change of the code, before anyone reads the plan.

## A gate

1. Write a script that fails on the first problem, and says through its status whether the plan has changes:

   ```bash exec
   mkdir -p ~/lab/checks && cd ~/lab/checks && \
   cp ../first/terraform.tf . && \
   cat > main.tf <<'TF'
   resource "local_file" "app_conf" {
     filename = "env/app.conf"
     content  = "port=8080\n"
   }
   TF
   cat > check.sh <<'SH'
   #!/usr/bin/env bash
   set -e
   terraform fmt -check -recursive
   terraform init -input=false > /dev/null
   terraform validate
   terraform plan -input=false -detailed-exitcode > /dev/null || [ $? -eq 2 ]
   SH
   chmod +x check.sh
   ```

   [Open check.sh](:open:checks/check.sh)

   `fmt -check` fails on a file that is not formatted, `validate` on an invalid one, and `plan -detailed-exitcode` exits with 2 when there are changes: they are expected in a review, so only another status is a failure.

2. The code as written passes:

   <!-- verify: expect="check status 0" -->

   ```bash exec
   cd ~/lab/checks && \
   ./check.sh; echo "check status $?"
   ```

3. A file that is not formatted fails, and `fmt -check` names it:

   <!-- verify: expect="check status 3" -->

   ```bash exec
   cd ~/lab/checks && \
   sed -i 's/content  =/content=/' main.tf && \
   { ./check.sh; echo "check status $?"; }
   ```

4. `terraform fmt` fixes it, and the gate passes again:

   <!-- verify: expect="check status 0" -->

   ```bash exec
   cd ~/lab/checks && \
   terraform fmt && \
   ./check.sh; echo "check status $?"
   ```

## More checks

- The [Trivy](../trivy) course scans Terraform with `trivy config`, before anything exists.
- The plan of a pull request is read by a person, so it is saved with `terraform plan -out=<file>` and applied with `terraform apply <file>`: what was reviewed is what runs.
  A plan file holds the variable values, sensitive ones in clear, so it is treated like the state.
- The lock file, the formatted code and the state's location are reviewed like any other change.
