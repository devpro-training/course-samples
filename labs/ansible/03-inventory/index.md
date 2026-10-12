# Inventory

The inventory is the list of the machines and of their groups.
Every command that follows reads one.

## The project

1. Create the project folder, with its configuration file:

   ```bash exec
   mkdir -p ~/lab/project/inventories/static ~/lab/project/group_vars && cd ~/lab/project && \
   cat > ansible.cfg <<'CFG'
   [defaults]
   interpreter_python = auto_silent
   CFG
   ```

   [Open ansible.cfg](:open:project/ansible.cfg)

   Ansible reads `ansible.cfg` of the current folder, so the project carries its own settings.
   `interpreter_python = auto_silent` picks the Python of the node without the warning that Ansible prints for each host otherwise.

## A static inventory

1. Declare three hosts in two groups, in YAML:

   ```bash exec
   cd ~/lab/project && \
   cat > inventories/static/hosts.yml <<'YML'
   all:
     children:
       web:
         hosts:
           web1:
           web2:
       db:
         hosts:
           db1:
   YML
   ```

   [Open hosts.yml](:open:project/inventories/static/hosts.yml)

   The groups are named after the function of the hosts, so a playbook says what it configures: `web`, not a list of names.

2. Read the inventory as Ansible does:

   <!-- verify: expect="|--db1" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-inventory -i inventories/static --graph
   ```

   `all` and `ungrouped` are the two groups that always exist: every host is in `all`.

3. The same inventory in the INI format, which the documentation shows next to YAML.
   The two give the same groups, and this course keeps YAML:

   <!-- verify: expect="|--db1" -->

   ```bash exec
   cd ~/lab/project && \
   cat > /tmp/hosts.ini <<'INI'
   [web]
   web1
   web2

   [db]
   db1
   INI
   ansible-inventory -i /tmp/hosts.ini --graph
   ```

## Variables

1. A value shared by every host goes in `group_vars/all.yml`, a file named after the group:

   ```bash exec
   cd ~/lab/project && \
   cat > group_vars/all.yml <<'YML'
   # The lab has no SSH server: every host is reached locally, and owns a folder.
   ansible_connection: local
   node_root: "{{ playbook_dir }}/nodes/{{ inventory_hostname }}"
   YML
   ```

   [Open all.yml](:open:project/group_vars/all.yml)

   `ansible_connection: local` replaces SSH here, which is the only difference with a real node.
   `playbook_dir` and `inventory_hostname` are magic variables, so the folder of each host is computed, not typed.

2. Variables of a group are read for its hosts, and a host has its own, merged by precedence: `all`, then the parent group, then the child group, then the host.
   `ansible-inventory --host` shows the result for one host:

   <!-- verify: expect="node_root" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-inventory -i inventories/static --host web1
   ```

   The file is found beside the playbook, and also beside the inventory.
   A value kept beside the playbook wins over one kept beside the inventory.

## An ad hoc command

1. Select hosts with a pattern, and run one module on them.
   `--list-hosts` only lists what the pattern matches:

   <!-- verify: expect="hosts (2)" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/static web --list-hosts
   ```

2. `ping` is not the network command: it connects, finds Python, and answers `pong`.
   It proves that Ansible can work on a host:

   <!-- verify: expect="pong" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/static all -m ansible.builtin.ping
   ```

3. Patterns combine groups, with `:` for a union, `:&` for an intersection and `:!` for an exclusion:

   <!-- verify: expect="hosts (3)" -->

   ```bash exec
   cd ~/lab/project && \
   ansible -i inventories/static 'web:db' --list-hosts
   ```
