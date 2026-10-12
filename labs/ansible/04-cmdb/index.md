# CMDB

A static file is a copy of what exists, and a copy drifts.
A **CMDB** (configuration management database) is the record of the machines, their role, their environment and their owner, kept by the people who create them.
An inventory that reads it at each run cannot be older than the machines.

In the lab, the CMDB is a JSON document served over HTTP, which stands for the API of a real one.

## The CMDB

1. Write the records of three machines:

   ```bash exec
   mkdir -p ~/lab/cmdb && cd ~/lab/cmdb && \
   cat > cmdb.json <<'JSON'
   {
     "items": [
       {"name": "web1", "role": "web", "env": "staging", "owner": "team-shop"},
       {"name": "web2", "role": "web", "env": "prod", "owner": "team-shop"},
       {"name": "db1", "role": "db", "env": "prod", "owner": "team-data"}
     ]
   }
   JSON
   ```

   [Open cmdb.json](:open:cmdb/cmdb.json)

2. Serve the folder on the port of the course, in the background:

   ```bash exec
   cd ~/lab/cmdb
   nohup python3 -m http.server "${CMDB_PORT}" --bind 127.0.0.1 > http.log 2>&1 &
   ```

3. Wait until it answers, and read a record the way a client does:

   <!-- verify: timeout=60 expect="team-data" -->

   ```bash exec
   wget -qO- --retry-connrefused "${CMDB_URL}"
   ```

## The inventory script

An executable inventory source is called by Ansible with `--list`, and prints a JSON document of the groups.
The documentation asks for two more things: `--host <name>` prints the variables of one host, and a top level `_meta` with `hostvars` spares one call per host.

1. Write the script: it reads the CMDB, and makes two groups of each record, one per role and one per environment:

   ```bash exec
   mkdir -p ~/lab/project/inventories/cmdb && cd ~/lab/project && \
   cat > inventories/cmdb/cmdb.py <<'PY'
   #!/usr/bin/env python3
   """Ansible inventory script: the hosts of a CMDB, grouped by role and environment."""
   import json
   import os
   import sys
   import urllib.request

   # Ansible calls the script with --list, and with --host <name> unless _meta is returned.
   if "--list" not in sys.argv:
       print("{}")
       sys.exit(0)

   with urllib.request.urlopen(os.environ["CMDB_URL"], timeout=10) as response:
       items = json.load(response)["items"]

   inventory = {"_meta": {"hostvars": {}}}
   for item in items:
       for group in (item["role"], "env_" + item["env"]):
           inventory.setdefault(group, {"hosts": []})["hosts"].append(item["name"])
       inventory["_meta"]["hostvars"][item["name"]] = {"owner": item["owner"]}

   print(json.dumps(inventory, indent=2))
   PY
   chmod +x inventories/cmdb/cmdb.py
   ```

   [Open cmdb.py](:open:project/inventories/cmdb/cmdb.py)

   The address of the CMDB is the variable `CMDB_URL`, so the same script serves any environment.
   The group `env_prod` is not `prod`: a group name is an identifier, so the prefix keeps it valid and tells what it groups.

2. Run it alone first, as Ansible does:

   <!-- verify: expect="env_staging" -->

   ```bash exec
   cd ~/lab/project && \
   inventories/cmdb/cmdb.py --list
   ```

3. Give it to Ansible with `-i`, and read the graph:

   <!-- verify: expect="@env_prod" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-inventory -i inventories/cmdb/cmdb.py --graph
   ```

   The hosts are in `web` and in `env_staging` or `env_prod`: the role and the environment are two independent ways to select them.

4. The variables of a host come from the CMDB, `owner` here, merged with `group_vars`:

   <!-- verify: expect="team-shop" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-inventory -i inventories/cmdb/cmdb.py --host web1
   ```

5. A pattern selects the web servers of production, the intersection of two groups:

   <!-- verify: expect="web2" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/cmdb/cmdb.py 'web:&env_prod' --list-hosts
   ```

## A host appears, a host disappears

1. A new web server is recorded in the CMDB, and nothing of the project changes:

   ```bash exec
   cd ~/lab/cmdb && \
   sed -i '2a\    {"name": "web3", "role": "web", "env": "prod", "owner": "team-shop"},' cmdb.json
   ```

2. The same command now matches it:

   <!-- verify: expect="web3" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/cmdb/cmdb.py 'web:&env_prod' --list-hosts
   ```

3. The machine is decommissioned, and its record is removed:

   ```bash exec
   cd ~/lab/cmdb && \
   sed -i '/web3/d' cmdb.json
   ```

4. It is gone from the inventory, and the later steps use the three records:

   <!-- verify: expect="hosts (1)" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/cmdb/cmdb.py 'web:&env_prod' --list-hosts
   ```

## The same idea with a plugin

The documentation recommends inventory plugins over scripts.
A plugin is a file with a `plugin:` key, and Ansible calls the code of a collection.
The collections are installed with `ansible-galaxy collection install`, and the files below are only read here, since they need a server and credentials.

Source          | Plugin                         | Credentials
----------------|--------------------------------|-------------------------------------------
NetBox          | `netbox.netbox.nb_inventory`   | `api_endpoint`, and a token or `NETBOX_TOKEN`
ServiceNow CMDB | `servicenow.itsm.now`          | `SN_HOST`, `SN_USERNAME`, `SN_PASSWORD`
Azure           | `azure.azcollection.azure_rm`  | the next course

```yaml
# netbox.yml: the hosts of NetBox, grouped by site and role
plugin: netbox.netbox.nb_inventory
api_endpoint: https://netbox.example.com
group_by:
  - site
  - role
```

```yaml
# inventory.now.yaml: the servers of the CMDB of ServiceNow, from the table cmdb_ci_server
plugin: servicenow.itsm.now
```

`ansible-inventory -i netbox.yml --graph` shows the result, as for the script above.

## Choosing

Source                  | Use it when                                  | The limit
------------------------|----------------------------------------------|----------------------------------------
A static file           | a few stable machines                        | a copy: it drifts from what exists
A plugin                | the source has an API with a plugin          | a collection and a credential to maintain
A script                | no plugin exists for the source              | the code is the team's to maintain

- The inventory is only as right as the CMDB: a wrong role or a missing record is a wrong or missed host.
- Ansible reads the CMDB and does not write it, so the record stays the owner's.
- Sources combine: `-i` can be repeated, and a folder is read file by file, in alphabetical order.
