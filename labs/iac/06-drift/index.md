# Drift

Someone logs in and fixes something by hand, at 3 a.m., with good reason.
The environment no longer matches the code, and nothing says so until the tool looks.

## A change by hand

1. Edit the port, open the mode of the page to everyone, and add a file of the tool's owner that the code does not mention:

   ```bash exec
   sed -i 's/9090/9999/' ~/lab/env/app.conf && \
   chmod 777 ~/lab/env/index.html && \
   echo "my notes" > ~/lab/env/notes.txt
   ```

2. Plan:

   <!-- verify: expect="mode 0777 -> 0644" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py plan
   ```

   Both changes are listed, with the value in the code and the value found.
   The notes file is not: the tool only manages what the code names.

3. Apply, and list the folder:

   <!-- verify: expect="notes.txt" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py apply && \
   ls -A ~/lab/env && cat ~/lab/env/app.conf
   ```

   The code wins: the port is back, and the page is no longer open to everyone.
   Terraform separates the two decisions: `terraform plan -refresh-only` reports drift and changes nothing, and a normal `plan` or `apply` would "attempt to revert your manual changes".
   When the manual change was right, the fix is to edit the code.

## Remove a resource

1. Delete the page from the code, and plan:

   <!-- verify: expect="- destroy index.html" -->

   ```bash exec
   cd ~/lab/declarative && \
   cat > infra.json <<'JSON'
   {
     "files": [
       {"path": "app.conf", "content": "port=9090\n", "mode": "0640"}
     ]
   }
   JSON
   python3 reconcile.py plan
   ```

   The idempotent script of the previous step could not do this.
   The tool knows the page was its own, because the state says so, and it leaves `notes.txt` alone, which is the reason a state exists.

2. Apply it, and list the folder:

   <!-- verify: expect=".state.json" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py apply && \
   ls -A ~/lab/env
   ```

   Without the state, a tool would have to choose between never deleting and deleting everything it does not know.
