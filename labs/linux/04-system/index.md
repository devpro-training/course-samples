# The system

A Linux system is a kernel, and the userland that comes with it.
Both describe themselves in files.

## The distribution

1. Read the identity of the distribution, a file that every modern distribution ships:

   <!-- verify: expect="ID=debian" -->

   ```bash exec target=linux
   grep -E '^(PRETTY_NAME|ID|ID_LIKE|VERSION_ID)=' /etc/os-release && \
   head -n 1 /etc/debian_version
   ```

   `ID` names the distribution, `ID_LIKE` the ones it derives from, and a script reads them to choose what to do.

   Distribution  | `ID`     | `ID_LIKE`
   --------------|----------|----------
   Debian        | `debian` | none
   Ubuntu        | `ubuntu` | `debian`
   Fedora        | `fedora` | none
   RHEL          | `rhel`   | `fedora`
   SLES          | `sles`   | `suse`
   Alpine        | `alpine` | none
   Arch          | `arch`   | none

   > [!NOTE]
   > The format of the file is described in the [os-release manual](https://www.freedesktop.org/software/systemd/man/latest/os-release.html).

## The kernel

1. Ask the kernel for its name, release and architecture:

   <!-- verify: expect="Linux" -->

   ```bash exec target=linux
   uname -srm
   ```

2. The kernel shows what it knows as files, in `/proc`.
   Its version, the memory, the processors and the time since it started are read with ordinary commands:

   <!-- verify: expect="MemAvailable:" -->

   ```bash exec target=linux
   head -n 1 /proc/version && \
   grep -E 'MemTotal|MemAvailable' /proc/meminfo && \
   grep -c '^processor' /proc/cpuinfo && \
   uptime
   ```

   > [!TIP]
   > `free -h`, `nproc` and `uptime` print the same data in a friendlier form.

## The tree

1. List the root of the tree:

   <!-- verify: expect="etc" -->

   ```bash exec target=linux
   ls /
   ```

2. On Debian, `/bin`, `/sbin` and `/lib` are links to the same folders under `/usr`, since a recent release merged them:

   <!-- verify: expect="usr/bin" -->

   ```bash exec target=linux
   ls -ld /bin /sbin /lib
   ```

3. Check who runs the shell, on which machine, and where it is:

   <!-- verify: expect="root" -->

   ```bash exec target=linux
   whoami && hostname && echo "${SHELL}" && pwd
   ```
