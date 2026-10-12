# Ansible

Ansible is the tool that makes machines match a description.
The description is a playbook, the machines are listed in an inventory, and nothing is installed on them.

---

## What it is

- **Agentless.**
  The documentation states that it "uses no agents and no additional custom security infrastructure", and needs "no servers, daemons, or databases".

- **A push over SSH.**
  The control node connects to each managed node, pushes small programs called **modules**, runs them, and removes them "when finished".
  The managed node needs Python and an account that can connect over SSH.

- **A playbook declares a desired state.**
  When the system is already in that state, Ansible "does not change anything, even if the playbook runs multiple times": this is idempotence.

- **No state file.**
  Unlike Terraform, each run reads the nodes, and reports `ok` or `changed` per task.

---

## How it works

![The inventory lists the hosts and groups, read from a static file or from a CMDB. The control node runs the playbook, whose tasks call modules. The modules are pushed over SSH to the managed nodes, run, report ok or changed, and are removed](../assets/ansible-architecture-dark.svg#gh-dark-mode-only)
![The inventory lists the hosts and groups, read from a static file or from a CMDB. The control node runs the playbook, whose tasks call modules. The modules are pushed over SSH to the managed nodes, run, report ok or changed, and are removed](../assets/ansible-architecture.svg#gh-light-mode-only)

---

## The key element: the inventory

- **Everything starts from the list of hosts.**
  A playbook says `hosts: web`, and the inventory says which machines are in `web`.

- **A static file** is enough for a few stable machines: INI or YAML, with groups and variables.

- **A dynamic inventory** is read from a source of truth when the command runs: a cloud, a directory, or a **CMDB** (configuration management database).
  The documentation recommends "plugins over scripts", and the scripts still work.

- **The hosts are typed once.**
  A host added to the CMDB is in the next run, with its groups, and no Ansible file changes.

---

## The commands

Command             | What it does
--------------------|-----------------------------------------------------------------------
`ansible-inventory` | shows the inventory as Ansible reads it: `--graph`, `--list`, `--host`
`ansible`           | runs one module on a group, an ad hoc command
`ansible-playbook`  | runs a playbook: `--check`, `--diff`, `--limit`, `--syntax-check`
`ansible-doc`       | the documentation of a module, offline
`ansible-vault`     | encrypts a value or a file
`ansible-lint`      | a separate package, the linter of playbooks and roles

---

## Versions

Fact                                                                                                         | Source
-------------------------------------------------------------------------------------------------------------|-----------------------------------------------
`ansible-core` is the engine, the `ansible` package adds the collections                                     | the installation guide
`ansible-core` 2.21 needs Python 3.12 to 3.14 on the control node, 2.19 needs 3.11 to 3.13                   | the support matrix
A series goes through critical fixes, then security fixes, then end of life, which is November 2026 for 2.19 | the support matrix, checked on 12 October 2026
The managed nodes need Python 3.9 or newer for 2.21, 3.8 or newer for 2.19                                   | the support matrix

The lab runs 2.19 because the image has Python 3.11.

---

## In this lab

Step      | What it shows
----------|----------------------------------------------------------------------------
Setup     | `ansible-core` in a virtual environment, pip checked against its checksum
Inventory | a static file, groups, variables, the graph, an ad hoc command
CMDB      | an inventory read from a CMDB over HTTP, a host that appears and disappears
Playbook  | commands against modules, idempotence, check mode and diff
Practices | variables per environment, a loop, a template, a handler
Structure | a role, Vault, `serial`, a staging rollout, and a linter

> The machines are folders of the lab container, reached with the `local` connection.
> A real node is reached over SSH, and only the connection variables change.
