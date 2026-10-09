# Setup

Linux is already installed in the virtual machine that has just been created for this lab, so there is nothing to install.
This step looks at the machine, and at the variables of the course.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Linux runs on a server, a laptop, a virtual machine, a container or a Raspberry Pi.
To follow this lab on a workstation, a Debian or an Ubuntu is enough, and the commands are the same.

System         | Linux
---------------|--------------------------------------------------------------------------------
Windows        | WSL: `wsl --install` in an administrator PowerShell installs Ubuntu by default
macOS          | A virtual machine, or a container: `docker run -it debian:bookworm`
Debian, Ubuntu | Already there, `sudo` gives the administrator rights used in this lab

[learn.microsoft.com/windows/wsl/install](https://learn.microsoft.com/windows/wsl/install) is the reference for WSL.

## The machine

The terminal of this lab is a Debian 12 virtual machine, with its own kernel.
Its shell belongs to `root`, the administrator, which is what the commands of the next steps need.

1. Check the system and the user:

   <!-- verify: expect="Debian GNU/Linux 12" -->

   ```bash exec target=linux
   . /etc/os-release && echo "${PRETTY_NAME}" && uname -sr && id -un
   ```

## Versions

Every name and version of this lab is a variable declared under `env:` in `lab.yaml`, so every shell of this machine has them.

1. Check that they arrived:

   <!-- verify: expect="user alice, group devs" -->

   ```bash exec target=linux
   echo "user ${LINUX_USER}, group ${LINUX_GROUP}, packages ${LINUX_PACKAGE} and ${SUDO_PACKAGE}"
   ```
