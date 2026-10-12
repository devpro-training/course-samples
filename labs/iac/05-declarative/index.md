# Declarative

A declarative description says what must exist.
A tool compares it with what exists, lists the differences, and makes them.
The tool of this step is 87 lines of Python, short enough to read, and it has the workflow of the real ones.

## The code

1. Describe the environment: two files, with their content and their mode.

   ```bash exec
   rm -rf ~/lab/env && \
   mkdir -p ~/lab/declarative && cd ~/lab/declarative && \
   cat > infra.json <<'JSON'
   {
     "files": [
       {"path": "app.conf", "content": "port=8080\n", "mode": "0640"},
       {"path": "index.html", "content": "<h1>Hello</h1>\n", "mode": "0644"}
     ]
   }
   JSON
   ```

   [Open infra.json](:open:declarative/infra.json)

2. Create the tool, which has two commands: `plan` reads, `apply` changes.

   ```bash exec
   cd ~/lab/declarative && \
   cat > reconcile.py <<'PY'
   #!/usr/bin/env python3
   """plan: show what would change. apply: change it."""
   import difflib
   import json
   import os
   import sys

   DESIRED = "infra.json"
   ROOT = os.path.expanduser("~/lab/env")
   STATE = os.path.join(ROOT, ".state.json")


   def load(path, default):
       try:
           with open(path) as f:
               return json.load(f)
       except FileNotFoundError:
           return default


   def read(path):
       full = os.path.join(ROOT, path)
       if not os.path.isfile(full):
           return None
       with open(full) as f:
           return {"content": f.read(), "mode": format(os.stat(full).st_mode & 0o777, "04o")}


   def plan():
       desired = {r["path"]: r for r in load(DESIRED, {"files": []})["files"]}
       managed = load(STATE, [])
       changes = []
       for path, want in desired.items():
           have = read(path)
           if have is None:
               changes.append(("create", path, want))
           elif have != {"content": want["content"], "mode": want["mode"]}:
               changes.append(("update", path, want, have))
       for path in managed:
           if path not in desired:
               changes.append(("destroy", path, None))
       return desired, changes


   def show(changes):
       symbol = {"create": "+", "update": "~", "destroy": "-"}
       for change in changes:
           print(f"{symbol[change[0]]} {change[0]} {change[1]}")
           if change[0] == "update":
               want, have = change[2], change[3]
               if want["mode"] != have["mode"]:
                   print(f"    mode {have['mode']} -> {want['mode']}")
               for line in difflib.unified_diff(have["content"].splitlines(), want["content"].splitlines(), lineterm="", n=0):
                   if line[0] in "+-" and line[:3] not in ("+++", "---"):
                       print(f"    {line}")
       counts = {kind: sum(1 for c in changes if c[0] == kind) for kind in symbol}
       if changes:
           print(f"Plan: {counts['create']} to create, {counts['update']} to update, {counts['destroy']} to destroy.")
       else:
           print(f"No changes: the environment matches {DESIRED}.")


   def apply(desired, changes):
       for change in changes:
           kind, path = change[0], change[1]
           full = os.path.join(ROOT, path)
           if kind == "destroy":
               os.remove(full)
           else:
               os.makedirs(os.path.dirname(full), exist_ok=True)
               with open(full, "w") as f:
                   f.write(change[2]["content"])
               os.chmod(full, int(change[2]["mode"], 8))
       os.makedirs(ROOT, exist_ok=True)
       with open(STATE, "w") as f:
           json.dump(sorted(desired), f)


   if len(sys.argv) == 2 and sys.argv[1] in ("plan", "apply"):
       desired, changes = plan()
       show(changes)
       if sys.argv[1] == "apply":
           apply(desired, changes)
           if changes:
               print("Applied.")
   else:
       sys.exit("usage: reconcile.py plan|apply")
   PY
   ```

   [Open reconcile.py](:open:declarative/reconcile.py)

   It compares each resource of `infra.json` with the folder, and lists a `create`, an `update` or a `destroy`.
   The list of paths it manages is written to `.state.json` after each `apply`.

## Plan, apply

1. The plan changes nothing:

   <!-- verify: expect="Plan: 2 to create" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py plan
   ```

2. Apply it, then apply again:

   <!-- verify: expect="Applied." -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py apply && \
   python3 reconcile.py apply
   ```

   The second run is a no-op, the same result as the idempotent script, with a message that says so.

## Change the code

1. Change the port in `infra.json`, the only place it is written:

   ```bash exec
   cd ~/lab/declarative && \
   sed -i 's/8080/9090/' infra.json
   ```

2. Read the plan: a difference of one line, not a script to run and hope:

   <!-- verify: expect="+port=9090" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py plan
   ```

3. Apply it, and read the state:

   <!-- verify: expect="Plan: 0 to create, 1 to update" -->

   ```bash exec
   cd ~/lab/declarative && \
   python3 reconcile.py apply && \
   cat ~/lab/env/.state.json
   ```

   The state is the list of what the tool created.
   Terraform's state file holds much more: the attributes of each resource, as the provider returned them.
