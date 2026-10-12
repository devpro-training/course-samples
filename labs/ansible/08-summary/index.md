# Summary

---

## Cheat sheet

Command / idea                                  | Means
------------------------------------------------|------------------------------------------------------------
`ansible-inventory -i <src> --graph`            | the groups and hosts as Ansible reads them; `--host <name>` the variables of one
`ansible <pattern> -m <module>`                 | one module on hosts; `web:db` union, `web:&env_prod` intersection, `:!` exclusion
`ansible-playbook <file>`                       | run a playbook
`--check --diff`                                | simulate and show the changes, nothing written
`--limit <group>`, `serial`                     | a smaller run, a few hosts at a time
`--syntax-check`                                | read the playbook, run nothing
`ansible-doc -s <module>`                       | the documentation of a module, offline
`group_vars/<group>.yml`, `host_vars/<host>.yml`| the data, by group and by host
`ansible-vault encrypt_string`                  | an encrypted value, inline
`ansible-lint`                                  | the rules of good practice, with profiles
`notify` and a handler                          | an action that follows a change, once

---

## Good practices

- **Keep it simple**: the modules before `command` and `shell`, a playbook that reads as a list of what is wanted.
- **Describe a state**, so a second run reports `changed=0`, and a report that changes means something.
- **Name** every play and task, and write the fully qualified module name and an explicit `state`.
- **DRY**: data in `group_vars`, a loop for the repetition, a template for a file, a role for a service.
- **One inventory source of truth**: a CMDB or a cloud read at each run, a static file only for a few stable machines, one folder per environment.
- **Group by function and by environment**, so a playbook says what it configures and a run is limited to staging first.
- **Look before changing**: `--check --diff`, `--syntax-check` and the linter in the pipeline.
- **Secrets**: Vault or a secret manager, `no_log`, a mode that only the owner reads, a password outside the repository.
- **Small steps**: `serial` and `--limit`, so a mistake stays small.
- **In Git**: playbooks, roles, inventory files and variables are reviewed like code.

---

## Further reading

- [Ansible documentation](https://docs.ansible.com/projects/ansible/latest/), the [inventory guide](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html) and [dynamic inventory](https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_dynamic_inventory.html).
- [Developing inventory](https://docs.ansible.com/projects/ansible/latest/dev_guide/developing_inventory.html): the contract of an inventory script.
- [Tips and tricks](https://docs.ansible.com/projects/ansible/latest/tips_tricks/ansible_tips_tricks.html) and the [sample setup](https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html).
- [Check mode and diff](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html) and [handlers](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_handlers.html).
- [The NetBox inventory plugin](https://docs.ansible.com/projects/ansible/latest/collections/netbox/netbox/nb_inventory_inventory.html) and the [ServiceNow collection](https://www.redhat.com/en/blog/certified-collection-servicenow).
- [Release and maintenance](https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html): the support matrix.

---

## Next

- Azure: the first cloud that Terraform manages, and an inventory plugin of Ansible reads.
- Kubernetes: the same desired state, for containers.
