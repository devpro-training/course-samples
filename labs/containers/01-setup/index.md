# Setup

The tools are installed in the virtual machine that has just been created for this lab.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

A container is a feature of the Linux kernel, so it needs a Linux machine.
Windows and macOS run a Linux virtual machine for it, and a tool manages that machine.

System         | Container tool
---------------|------------------------------------------------------------------
Windows        | WSL 2 with a Linux distribution, [Docker Desktop](https://docs.docker.com/desktop/) or [Podman Desktop](https://podman-desktop.io/)
macOS          | [Docker Desktop](https://docs.docker.com/desktop/) or [Podman Desktop](https://podman-desktop.io/)
Linux          | Docker Engine or Podman, from the distribution

## The machine

Namespaces and cgroups are set up with administrator rights, on a kernel the machine owns.
The lab image gives neither, and this lab declares a virtual machine of its own instead (`runtime: vm` in `lab.yaml`): a Debian 12 userland, with its own kernel, and a shell that is `root` already.
The terminal of this lab is that machine.

1. Check the system and the user:

   <!-- verify: expect="Debian GNU/Linux 12" -->

   ```bash exec target=machine
   . /etc/os-release && echo "${PRETTY_NAME}" && uname -r && id -un
   ```

## Versions

Every version and image of this lab is a variable declared under `env:` in `lab.yaml`, so every shell of this machine has them.

1. Check that they arrived:

   <!-- verify: expect="Podman 4.3" -->

   ```bash exec target=machine
   echo "Podman ${PODMAN_VERSION}, ${ALPINE_IMAGE}"
   ```

## The tools

1. Install the tools of the lab.
   `busybox-static` is a single program with the common Unix commands, which becomes the content of the container built by hand.
   `iproute2` shows the network of the machine, and Podman is a container tool, installed here to show the standard way to run what was built by hand.
   `DEBIAN_FRONTEND=noninteractive` stops `apt-get` from asking questions that nobody would answer:

   <!-- verify: requires=network timeout=300 expect="podman version 4.3" -->

   ```bash exec target=machine
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-get install -y -qq busybox-static="${BUSYBOX_VERSION}" podman="${PODMAN_VERSION}" iproute2 > /dev/null 2>&1 ; \
   podman --version
   ```

2. `unshare` and `chroot` are part of the system already:

   <!-- verify: expect="/usr/bin/unshare" -->

   ```bash exec target=machine
   command -v unshare chroot busybox
   ```

> [!NOTE]
> The editor of the lab shows the files of the lab container, not of this machine, so the files of this course are written by the commands, which show their content.
