<!-- include: ../../shared/setup.md -->

## On a workstation

Ansible runs on Linux, macOS and the BSDs, and on Windows only inside WSL.
The managed machines are reached over SSH, so a workstation needs no more than Python and the package.

System         | Command
---------------|-----------------------------------------------------
Linux, WSL     | `pipx install --include-deps ansible`, or the virtual environment of this step
macOS          | `brew install ansible`, or `pipx`
Windows        | WSL, since Windows without WSL is not supported as a control node

The machines of this lab are folders of the lab container, reached with the `local` connection, so no SSH server and no virtual machine are needed.

<!-- include: ../../shared/setup-ansible.md -->
