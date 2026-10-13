# Practices

One playbook for every environment, written once.
What differs between the environments is data, kept in `group_vars`, and the groups come from the CMDB.

## Keep it DRY

1. The CMDB of the previous step answers, since the inventory is read from it at each command:

   <!-- verify: expect="team-data" -->

   ```bash exec
   wget -qO- "${CMDB_URL}"
   ```

   When it does not, `cd ~/lab/cmdb` and start it again with the `nohup python3 -m http.server` command of the previous step.

2. Start from empty nodes, and use the CMDB as the inventory of the project from now on.
   The inventory is a setting of the project, so `-i` is no longer typed:

   ```bash exec
   cd ~/lab/project && \
   rm -rf nodes bad.yml good.yml && \
   cat > ansible.cfg <<'CFG'
   [defaults]
   inventory = inventories/cmdb/cmdb.py
   interpreter_python = auto_silent
   CFG
   ```

   [Open ansible.cfg](:open:project/ansible.cfg)

3. A value that is true everywhere goes in `group_vars/all.yml`, and a value that differs goes in the file of the group that differs.
   The environments are groups of the CMDB, so they are files:

   ```bash exec
   cd ~/lab/project && \
   cat >> group_vars/all.yml <<'YML'

   app_dirs:
     - etc/app
     - var/log/app
     - var/lib/app
   app_port: 8080
   log_level: info
   YML
   cat > group_vars/env_staging.yml <<'YML'
   app_port: 9090
   log_level: debug
   YML
   cat > group_vars/env_prod.yml <<'YML'
   log_level: warning
   YML
   ```

   [Open all.yml](:open:project/group_vars/all.yml)

   Staging overrides two values, production one, and the port of production is the default: nothing is repeated.

4. The configuration file is a template, with the values as variables.
   The owner comes from the CMDB:

   ```bash exec
   cd ~/lab/project && \
   mkdir -p templates && \
   cat > templates/app.conf.j2 <<'J2'
   # Managed by Ansible, local changes are overwritten.
   port={{ app_port }}
   log_level={{ log_level }}
   owner={{ owner }}
   J2
   ```

   [Open app.conf.j2](:open:project/templates/app.conf.j2)

5. The playbook has a loop for the three folders, instead of three tasks, and a handler.
   A **handler** is a task that only runs when notified, once at the end of the play, and only when the notifying task changed something:

   ```bash exec
   cd ~/lab/project && \
   cat > site.yml <<'YML'
   - name: Configure the web servers
     hosts: web
     tasks:
       - name: Create the folders of the application
         ansible.builtin.file:
           path: "{{ node_root }}/{{ item }}"
           state: directory
           mode: "0755"
         loop: "{{ app_dirs }}"

       - name: Install the configuration
         ansible.builtin.template:
           src: app.conf.j2
           dest: "{{ node_root }}/etc/app/app.conf"
           mode: "0644"
         notify: Reload the application

     handlers:
       - name: Reload the application
         ansible.builtin.debug:
           msg: "reload on {{ inventory_hostname }}"
   YML
   ```

   [Open site.yml](:open:project/site.yml)

   The handler stands for the reload of a service, a `debug` message in the lab, which has none.

## Look, apply, apply again

1. The plan, with the content of the two files, one per host:

   <!-- verify: expect="+log_level=debug" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml --check --diff
   ```

2. Apply: the configuration changed, so the handler runs:

   <!-- verify: expect="reload on web1" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml
   ```

3. The two files differ by their environment only:

   <!-- verify: expect="log_level=warning" -->

   ```bash exec
   cd ~/lab/project && \
   grep -H -E "port|log_level" nodes/*/etc/app/app.conf
   ```

4. Apply again: nothing changed, so the handler does not run:

   <!-- verify: expect="changed=0" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml
   ```

## One change, one place

1. Production logs only errors: one line, in one file:

   ```bash exec
   cd ~/lab/project && \
   sed -i 's/^log_level: warning/log_level: error/' group_vars/env_prod.yml
   ```

2. `--limit` restricts the run to a group of the inventory, and the diff is the line that changed:

   <!-- verify: expect="+log_level=error" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml --limit env_prod --diff
   ```

## What is applied

Practice                                      | Where it shows
----------------------------------------------|-------------------------------------------
Keep it simple, use the modules, not commands | `file` and `template`, no `shell`
Name every play and task, say why             | the names are the lines of the output
Fully qualified names, an explicit `state`    | `ansible.builtin.file`, `state: directory`
Describe the state, so a run is idempotent    | `changed=0` on the second run
Look before changing                          | `--check --diff`, `--syntax-check`
DRY: one playbook, the data apart             | `group_vars`, a loop, a template
Group by function, and by environment         | `web`, `db`, `env_prod`, `env_staging`
Handlers for what follows a change            | the reload only when the file changed
