# Isolate a process

A container starts with a directory that becomes its root, then gets its own view of the system.
Both are done here with the commands of the system, before any container tool.

## A root filesystem

1. Create a directory with the shape of a minimal system, and fill it with busybox.
   `chroot` runs `busybox --install` from inside the directory, so the links are relative to the new root:

   <!-- verify: expect="ash" -->

   ```bash exec target=machine
   mkdir -p ~/lab/rootfs/bin ~/lab/rootfs/proc && \
   cp "$(command -v busybox)" ~/lab/rootfs/bin/ && \
   chroot ~/lab/rootfs /bin/busybox --install -s /bin && \
   ls ~/lab/rootfs/bin | head -n 12 | tr "\n" " "
   ```

## chroot

1. Start a shell with that directory as its root.
   It sees `bin` and `proc` and nothing else, so the files of the machine are out of reach:

   <!-- verify: expect="No such file" -->

   ```bash exec target=machine
   { chroot ~/lab/rootfs /bin/sh -c 'ls /; ls /etc' || true; }
   ```

   The command fails on purpose: `/etc` does not exist in this root.

2. `chroot` changes the root and nothing else.
   The hostname is still the one of the machine:

   ```bash exec target=machine
   hostname && chroot ~/lab/rootfs /bin/hostname
   ```

## Namespaces

`unshare` starts a command in new namespaces:

Option       | Namespace | The process gets its own
-------------|-----------|-------------------------------------------
`--pid`      | PID       | process numbers, so it is process 1
`--uts`      | UTS       | hostname
`--net`      | network   | interfaces, which are empty
`--mount`    | mount     | mounts, so `/proc` can be its own
`--fork`     |           | starts the command as a child, required by `--pid`

1. Run the same shell with its own hostname, processes and network:

   <!-- verify: expect="lo: <LOOPBACK>" -->

   ```bash exec target=machine
   unshare --pid --fork --uts --net --mount --mount-proc="$HOME/lab/rootfs/proc" \
     chroot ~/lab/rootfs /bin/sh -c 'hostname boxed; hostname; ps; ip link'
   ```

   Inside, the hostname is `boxed`, the shell is process 1, `ps` lists nothing else, and the only network interface is the loopback.

2. The machine did not change:

   ```bash exec target=machine
   hostname
   ```

3. The namespaces of a process are listed in `/proc`.
   The identifier of the PID namespace differs inside and outside:

   <!-- verify: expect="pid:[" -->

   ```bash exec target=machine
   readlink /proc/self/ns/pid && \
   unshare --pid --fork --mount-proc="$HOME/lab/rootfs/proc" chroot ~/lab/rootfs /bin/readlink /proc/self/ns/pid
   ```

> [!NOTE]
> A container tool does these same steps, with an image unpacked as the root filesystem, and adds the user, IPC and cgroup namespaces.
