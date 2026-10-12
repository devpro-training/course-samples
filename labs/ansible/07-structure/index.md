# Structure

The playbook of the previous step grows with every service.
The tasks move to a **role**, a folder with a fixed layout that a playbook uses by name, and the playbook stays a list of what runs where.

## A role

1. Move the template, then write the tasks and the handler of the role `app`, with the same content as before:

   ```bash exec
   cd ~/lab/project && \
   mkdir -p roles/app/tasks roles/app/handlers roles/app/templates && \
   mv templates/app.conf.j2 roles/app/templates/ && rmdir templates && \
   cat > roles/app/tasks/main.yml <<'YML'
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
   YML
   cat > roles/app/handlers/main.yml <<'YML'
   - name: Reload the application
     ansible.builtin.debug:
       msg: "reload on {{ inventory_hostname }}"
   YML
   ```

   [Open main.yml](:open:project/roles/app/tasks/main.yml)

   Ansible looks for `tasks/main.yml`, `handlers/main.yml` and `templates/` of a role by name, so `src: app.conf.j2` needs no path.

2. The playbook only names the role:

   ```bash exec
   cd ~/lab/project && \
   cat > site.yml <<'YML'
   - name: Configure the web servers
     hosts: web
     roles:
       - app
   YML
   ```

   [Open site.yml](:open:project/site.yml)

3. The result is the same, so nothing changes:

   <!-- verify: expect="changed=0" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml
   ```

## A secret

A password in `group_vars` is a password in Git.
**Ansible Vault** encrypts a value, with a password that stays out of the repository.

1. Create a password file for the lab, outside the project, and tell Ansible where it is.
   A real password comes from a secret manager:

   ```bash exec
   cd ~/lab/project && \
   echo "lab-only-password" > ~/lab/.vault-pass && chmod 600 ~/lab/.vault-pass && \
   echo "vault_password_file = ~/lab/.vault-pass" >> ansible.cfg
   ```

2. Encrypt the value into the variable file of the group.
   `group_vars/all` becomes a folder, so the plain values and the encrypted one are two files of the same group:

   <!-- verify: expect="ANSIBLE_VAULT;1.1;AES256" -->

   ```bash exec
   cd ~/lab/project && \
   mkdir group_vars/all && mv group_vars/all.yml group_vars/all/vars.yml && \
   ansible-vault encrypt_string 's3cr3t-value' --name app_secret | tee group_vars/all/vault.yml
   ```

   [Open vault.yml](:open:project/group_vars/all/vault.yml)

   The name of the variable stays readable, so it can be searched, and only the value is encrypted.

3. A task installs the secret with a mode that only the owner reads.
   `no_log` keeps the value out of the output of the run:

   ```bash exec
   cd ~/lab/project && \
   cat >> roles/app/tasks/main.yml <<'YML'

   - name: Install the secret of the application
     ansible.builtin.copy:
       content: "{{ app_secret }}\n"
       dest: "{{ node_root }}/etc/app/secret"
       mode: "0600"
     no_log: true
   YML
   ```

4. Apply, and read the mode of the file:

   <!-- verify: expect="-rw------- 1 labuser" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml && \
   ls -l nodes/web1/etc/app/secret
   ```

   The project holds no copy of the value in clear:

   <!-- verify: expect="plain copies in the project: 0" -->

   ```bash exec
   cd ~/lab/project && \
   echo "plain copies in the project: $(grep -rl 's3cr3t' group_vars roles | wc -l)"
   ```

## Roll out with care

1. `serial` updates a few hosts at a time, so a mistake stops after the first batch instead of reaching all of them:

   ```bash exec
   cd ~/lab/project && \
   cat > site.yml <<'YML'
   - name: Configure the web servers
     hosts: web
     serial: 1
     roles:
       - app
   YML
   ```

2. Staging first, then the rest.
   `--limit` takes the group of the CMDB, and the play runs one host at a time:

   <!-- verify: expect="PLAY [Configure the web servers]" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-playbook site.yml --limit env_staging && \
   ansible-playbook site.yml
   ```

## A linter

`ansible-lint` is a separate package, which applies the practices of the previous step as rules.

1. Install it in the same environment, at the pinned version, with the pip that the setup used:

   <!-- verify: requires=network timeout=300 expect="Successfully installed" -->

   ```bash exec
   cd ~ && \
   wget -q "${PIP_WHEEL_URL}" && \
   echo "${PIP_WHEEL_SHA256}  pip-${PIP_VERSION}-py3-none-any.whl" | sha256sum --check --quiet && \
   python3 "pip-${PIP_VERSION}-py3-none-any.whl/pip" --python ~/.ansible-venv/bin/python install "ansible-lint==${ANSIBLE_LINT_VERSION}" && \
   rm "pip-${PIP_VERSION}-py3-none-any.whl"
   ```

2. Without a configuration file, the linter does not find the root of the project and warns that its cache folder, `/.ansible`, is not writable.
   The file marks the root and names the profile, here the strictest one, `production`:

   ```bash exec
   cd ~/lab/project && \
   echo "profile: production" > .ansible-lint
   ```

3. Lint the project:

   <!-- verify: expect="Passed: 0 failure(s)" -->

   ```bash exec
   cd ~/lab/project && \
   ansible-lint
   ```

4. A `shell` task is what the linter refuses, as in the first playbook of this course:

   <!-- verify: expect="Failed:" -->

   ```bash exec
   cd ~/lab/project && \
   mkdir -p /tmp/lint-demo && \
   printf -- '- hosts: web\n  tasks:\n    - ansible.builtin.shell: echo ok\n' > /tmp/lint-demo/bad.yml && \
   { ansible-lint /tmp/lint-demo/bad.yml || true; }
   ```

## The layout

```txt
project/
├── ansible.cfg           ← the settings of the project
├── .ansible-lint         ← the profile of the linter
├── inventories/          ← one folder per source: static, cmdb
├── group_vars/           ← the data, per group: all, web, env_prod
├── site.yml              ← the playbook: where each role runs
└── roles/app/            ← tasks, handlers, templates
```

The sample setup of the documentation has the same shape: inventory, `group_vars`, `site.yml` and `roles`, so that `site.yml` configures the whole infrastructure and a smaller playbook one tier of it.
