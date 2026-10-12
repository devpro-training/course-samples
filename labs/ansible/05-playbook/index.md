# Playbook

A playbook is a list of plays, and a play maps a group of hosts to tasks.
A task calls a **module**, and a module describes a state, not a command.

The same two changes are written twice: with commands, then with modules.

## With commands

1. Create a folder and a file with `command` and `shell`:

   ```bash exec
   cd ~/lab/project && \
   cat > bad.yml <<'YML'
   - hosts: web
     tasks:
       - command: mkdir -p {{ node_root }}/etc/app
       - shell: echo "port=8080" > {{ node_root }}/etc/app/app.conf
   YML
   ```

   [Open bad.yml](:open:project/bad.yml)

2. Run it twice, with the static inventory.
   The first run is a success:

   <!-- verify: expect="changed=2" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static bad.yml
   ```

3. The second run changes nothing on the nodes, and still reports `changed=2`:

   <!-- verify: expect="changed=2" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static bad.yml
   ```

   Ansible cannot know what a command did, so it always says `changed`, and a report that is always red tells nothing.

4. Check mode runs without changing anything, and a command is skipped, since Ansible cannot predict it:

   <!-- verify: expect="skipped=2" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static bad.yml --check
   ```

## With modules

1. The same two changes with `file` and `copy`, which describe the state wanted.
   The names say what and why, the modules are written in full (`ansible.builtin.copy`, the fully qualified collection name), and `state` is explicit:

   ```bash exec
   cd ~/lab/project && \
   rm -rf nodes && \
   cat > good.yml <<'YML'
   - name: Configure the web servers
     hosts: web
     tasks:
       - name: Create the configuration folder
         ansible.builtin.file:
           path: "{{ node_root }}/etc/app"
           state: directory
           mode: "0755"

       - name: Install the configuration
         ansible.builtin.copy:
           content: "port=8080\n"
           dest: "{{ node_root }}/etc/app/app.conf"
           mode: "0644"
   YML
   ```

   [Open good.yml](:open:project/good.yml)

2. Look at the documentation of a module, offline, from the installed package:

   <!-- verify: expect="Copy files to remote locations" -->

   ```bash exec
   ansible-doc -s ansible.builtin.copy | head -8
   ```

3. Check the syntax, which reads the playbook and runs nothing:

   <!-- verify: expect="playbook: good.yml" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static good.yml --syntax-check
   ```

4. Run it: two nodes, two changes each:

   <!-- verify: expect="changed=2" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static good.yml
   ```

5. Run it again: the nodes match, so nothing changes.
   This is idempotence, and the report is true:

   <!-- verify: expect="changed=0" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static good.yml
   ```

## Look before changing

1. Change the port in the playbook, the only place it is written:

   ```bash exec
   cd ~/lab/project && \
   sed -i 's/8080/9090/' good.yml
   ```

2. `--check --diff` is the plan of Ansible: the tasks run in simulation, and each module shows what it would change.
   Nothing is written:

   <!-- verify: expect="+port=9090" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static good.yml --check --diff
   ```

   A module that does not support check mode "reports nothing and does nothing", which `command` showed above.

3. The files are unchanged, and the apply changes them:

   <!-- verify: expect="port=8080" -->

   ```bash exec
   cd ~/lab/project && \
   grep -H port nodes/*/etc/app/app.conf
   ```

   <!-- verify: expect="changed=1" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook -i inventories/static good.yml
   ```
