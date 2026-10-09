# Summary

---

## Cheat sheet

Command                         | Does
--------------------------------|--------------------------------------------
`uname -a`, `/etc/os-release`   | The kernel, the distribution
`pwd`, `ls -la`, `cd`           | Where, what, move
`mkdir -p`, `cp`, `mv`, `rm -r` | Create, copy, move, remove
`grep`, `head`, `tail`, `wc -l` | Search, cut, count
`>`, `>>`, `2>`                 | Write, append, write the errors to a file
`id`, `chmod`, `chown`          | Who, what is allowed, whose
`sudo <command>`                | Run one command as `root`
`apt update`, `apt install`     | Refresh, install (Debian, Ubuntu)
`dpkg -l`, `dpkg -S`, `dpkg -L` | What is installed, which package owns a file
`ps`, `top`, `kill`             | List, watch, stop
`systemctl`, `journalctl`       | Manage a service, read its log

---

## Good practices

- Work as a user, and use `sudo` for the one command that needs it.

- Install with the package manager, and keep the machine updated.

- Check a command that removes with `ls`, since there is no recycle bin.

- Edit `/etc/sudoers` with `visudo`, and a unit file with `systemd-analyze verify` after.

- Read the log of a service before restarting it.

---

## Distributions, again

- Debian and Ubuntu: `apt`, the reference of this lab.

- Red Hat family: `dnf`, with Fedora, CentOS Stream, RHEL, AlmaLinux and Rocky Linux.

- SUSE: `zypper`, with openSUSE and SLES.

- Alpine and Arch: `apk` and `pacman`, small and rolling.

---

## Next

- Container base images: what a minimal Linux looks like in a container.

- The [kernel documentation](https://docs.kernel.org), the [Debian reference](https://www.debian.org/doc/manuals/debian-reference/) and the manual pages at [man7.org](https://man7.org/linux/man-pages/).
