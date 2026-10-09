# Why sudo

Working as `root` all day is risky: a mistyped `rm -r` or a malicious script has no limit.
Working as a user is safe, and **sudo** runs a single command with the rights of `root` when it is needed, after the password of the user.

## Without sudo

1. A user cannot change the system, here to install a package:

   <!-- verify: expect="Permission denied" -->

   ```bash exec target=linux
   { runuser -u "${LINUX_USER}" -- apt-get install -y "${LINUX_PACKAGE}" || true; }
   ```

## Install sudo

1. `sudo` is a package, installed by `root`.
   The program has the **setuid** bit, the `s` in its permissions, so it runs as its owner, `root`, whoever starts it:

   <!-- verify: requires=network timeout=180 expect="-rwsr-xr-x" -->

   ```bash exec target=linux
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-get install -y -qq "${SUDO_PACKAGE}" > /dev/null 2>&1 ; \
   ls -l /usr/bin/sudo
   ```

2. The user is not allowed yet.
   `sudo -S` reads the password from the input, which a script needs, where a person types it:

   <!-- verify: expect="not in the sudoers file" -->

   ```bash exec target=linux
   { echo "${LINUX_PASSWORD}" | runuser -u "${LINUX_USER}" -- sudo -S true || true; }
   ```

## Who may

1. The rules are in `/etc/sudoers`, a file that is edited with `visudo`, which checks the syntax first, since a mistake there locks everyone out.
   On Debian, the members of the group `sudo` may run anything:

   <!-- verify: expect="parsed OK" -->

   ```bash exec target=linux
   grep -E '^(root|%sudo)' /etc/sudoers && \
   visudo -c
   ```

   Rule                   | Reads
   -----------------------|------------------------------------------------------------
   `%sudo ALL=(ALL:ALL) ALL` | Members of `sudo`, on any host, as any user and group, any command

2. Add the user to the group `sudo`:

   <!-- verify: expect="27(sudo)" -->

   ```bash exec target=linux
   usermod -aG sudo "${LINUX_USER}" && \
   id "${LINUX_USER}"
   ```

## With sudo

1. The command runs as `root`, and `SUDO_USER` keeps the name of the user who asked:

   <!-- verify: expect="whoami: root" -->

   ```bash exec target=linux
   echo "${LINUX_PASSWORD}" | runuser -u "${LINUX_USER}" -- sudo -S sh -c 'echo "whoami: $(whoami)"; echo "sudo user: $SUDO_USER"'
   ```

2. The same installation that failed now works:

   <!-- verify: requires=network timeout=120 expect="tree v2" -->

   ```bash exec target=linux
   echo "${LINUX_PASSWORD}" | runuser -u "${LINUX_USER}" -- sudo -S apt-get install -y -qq "${LINUX_PACKAGE}" > /dev/null 2>&1 ; \
   "${LINUX_PACKAGE}" --version
   ```

> [!TIP]
> `sudo -l` lists what the user may run, `sudo -u <user> <command>` runs as another user, and `sudo -i` opens a shell as `root`.
> A file in `/etc/sudoers.d/` adds a rule without editing the main file.
