# Linux

The operating system under most servers, containers and clouds.

---

## What Linux is

- Strictly, **Linux is a kernel**: the program that talks to the hardware and shares it between programs.

- Written from scratch by Linus Torvalds, as a clone of Unix, and released under version 2 of the GNU GPL.

- Developed in the open, and published at [kernel.org](https://www.kernel.org), with stable and longterm branches.

- Everything else, the shell, the commands, the libraries, comes from other projects, mostly GNU.

---

## Kernel, userland, distribution

![From the hardware to the applications, the kernel, the system calls, the libraries and the commands, and what a distribution adds](../assets/linux-layers-dark.svg#gh-dark-mode-only)
![From the hardware to the applications, the kernel, the system calls, the libraries and the commands, and what a distribution adds](../assets/linux-layers.svg#gh-light-mode-only)

---

## Everything is a file

- Programs never touch the hardware: they ask the kernel through **system calls**, and the kernel answers with files, processes and sockets.

- A disk, a terminal, a running process or the memory is read like a file: `/dev`, `/proc` and `/sys`.

- One tree starts at `/`, with no drive letters.

- The layout is standardised by the Filesystem Hierarchy Standard, version 3.0.

---

## The tree

Directory | Holds
----------|----------------------------------------------
`/etc`    | Configuration of this machine
`/home`   | Home directories of the users
`/root`   | Home directory of `root`
`/usr`    | Installed programs and libraries
`/var`    | Data that changes: logs, caches, databases
`/tmp`    | Temporary files
`/dev`    | Devices
`/proc`   | The kernel's view of processes, as files

---

## Users, and why root

- Every process runs as a **user**, and every file has an owner, a group and permissions.

- `root`, user number 0, is not checked by the kernel: it can read, write and kill anything.

- Working as `root` every day is dangerous, so people work as themselves and borrow the rights with **sudo**.

---

## In this lab

Topic          | Commands
---------------|---------------------------------------------------------
The system     | `uname`, `/etc/os-release`, `/proc`, `ls /`
Files          | `pwd`, `ls`, `cd`, `mkdir`, `cp`, `mv`, `rm`
Text and pipes | `grep`, `head`, `tail`, `wc`, `sort`, `|`, `>`
Users, groups  | `id`, `adduser`, `usermod`, `chmod`, `chown`
Sudo           | `sudo`, `/etc/sudoers`
Packages       | `apt`, `dpkg`
Processes      | `ps`, `top`, `kill`, `&`
Services       | `systemd`, `systemctl`, `journalctl`
