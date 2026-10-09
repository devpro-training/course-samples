# Packages

Software is not downloaded from a web site and copied by hand: a **package manager** installs it from a **repository**, with its dependencies, and knows which files belong to which package.
On Debian and Ubuntu, `dpkg` handles the `.deb` files on the machine, and `apt` fetches them from the repositories and resolves the dependencies.

## Repositories

1. The repositories of the machine are listed in `/etc/apt/sources.list.d/`.
   The packages are signed, and `Signed-By` is the key that `apt` checks them with:

   <!-- verify: expect="URIs:" -->

   ```bash exec target=linux
   grep -E '^(Types|URIs|Suites|Components|Signed-By):' /etc/apt/sources.list.d/*.sources
   ```

2. Download the index of the packages the repositories offer, which is what `apt update` does, and search it:

   <!-- verify: requires=network timeout=120 expect="displays an indented directory tree" -->

   ```bash exec target=linux
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-cache search --names-only "^${LINUX_PACKAGE}\$"
   ```

## A package

1. Which version is available, from which repository, and what it depends on:

   <!-- verify: expect="Candidate:" -->

   ```bash exec target=linux
   apt-cache policy "${LINUX_PACKAGE}" && \
   apt-cache depends "${LINUX_PACKAGE}"
   ```

2. Its description, as the repository publishes it:

   <!-- verify: expect="Description:" -->

   ```bash exec target=linux
   apt-cache show "${LINUX_PACKAGE}" | grep -E '^(Package|Version|Depends|Homepage|Description):'
   ```

## Installed

1. `dpkg` answers about the packages installed on the machine: its state, the files it put on the disk, and which package a file belongs to:

   <!-- verify: expect="tree: /usr/bin/tree" -->

   ```bash exec target=linux
   dpkg -l "${LINUX_PACKAGE}" && \
   dpkg -L "${LINUX_PACKAGE}" | grep bin && \
   dpkg -S /usr/bin/tree
   ```

2. Remove the package, check that the command is gone, and install it again.
   The shell remembers where it found a command, so `hash -r` makes it forget before the check:

   <!-- verify: requires=network timeout=120 expect="status 1 after removal" -->

   ```bash exec target=linux
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get remove -y -qq "${LINUX_PACKAGE}" > /dev/null 2>&1 ; \
   hash -r ; \
   { command -v "${LINUX_PACKAGE}" || echo "status $? after removal"; } && \
   apt-get install -y -qq "${LINUX_PACKAGE}" > /dev/null 2>&1 ; \
   "${LINUX_PACKAGE}" --version
   ```

3. Preview the updates the machine would apply, with `-s` to simulate, before doing it with `apt-get upgrade`:

   <!-- verify: expect="upgraded, " -->

   ```bash exec target=linux
   apt-get -s upgrade | grep -E '^[0-9]+ upgraded'
   ```

> [!NOTE]
> `apt` is meant for people, with a progress bar and colors, and `apt-get` and `apt-cache` for scripts, with an output that does not change.

## Other distributions

Each family has its own tool, and does the same things:

Task               | Debian, Ubuntu    | Fedora, RHEL      | openSUSE, SLES      | Alpine            | Arch
-------------------|-------------------|-------------------|---------------------|-------------------|------------------
Refresh the index  | `apt update`      | `dnf makecache`   | `zypper refresh`    | `apk update`      | `pacman -Sy`
Install            | `apt install x`   | `dnf install x`   | `zypper install x`  | `apk add x`       | `pacman -S x`
Remove             | `apt remove x`    | `dnf remove x`    | `zypper remove x`   | `apk del x`       | `pacman -R x`
Search             | `apt search x`    | `dnf search x`    | `zypper search x`   | `apk search x`    | `pacman -Ss x`
Update all         | `apt upgrade`     | `dnf upgrade`     | `zypper update`     | `apk upgrade`     | `pacman -Syu`
Which package owns | `dpkg -S file`    | `rpm -qf file`    | `rpm -qf file`      | `apk info -W file`| `pacman -Qo file`

> [!NOTE]
> Installing, removing and updating need `root`, which is why a user goes through `sudo`.
