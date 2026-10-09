# Limit what a process uses

A namespace hides, a control group caps.
The kernel exposes cgroups (version 2) as a file tree under `/sys/fs/cgroup`: a directory is a group, a file is a setting, and writing a process number to `cgroup.procs` moves it into the group.

## A group

1. The controllers the kernel offers:

   <!-- verify: expect="memory" -->

   ```bash exec target=machine
   cat /sys/fs/cgroup/cgroup.controllers
   ```

2. Enable the memory and processes controllers for the child groups, create a group, and set two limits.
   Swap is disabled for the group, otherwise memory over the limit is moved to swap and the process goes on:

   <!-- verify: expect="20971520" -->

   ```bash exec target=machine
   echo "+memory +pids" > /sys/fs/cgroup/cgroup.subtree_control && \
   mkdir -p /sys/fs/cgroup/demo && \
   echo 20M > /sys/fs/cgroup/demo/memory.max && \
   echo 0 > /sys/fs/cgroup/demo/memory.swap.max && \
   echo 10 > /sys/fs/cgroup/demo/pids.max && \
   cat /sys/fs/cgroup/demo/memory.max /sys/fs/cgroup/demo/pids.max
   ```

## The memory limit

1. Run a program that asks for 100 MiB in the group.
   The kernel kills it, and the status of a process killed by signal 9 is 137:

   <!-- verify: expect="status 137" -->

   ```bash exec target=machine
   sh -c 'echo $$ > /sys/fs/cgroup/demo/cgroup.procs; exec python3 -c "x = bytearray(100 * 1024 * 1024)"'
   echo "status $?"
   ```

2. The group counted it:

   <!-- verify: expect="oom_kill 1" -->

   ```bash exec target=machine
   grep -E "^(max|oom_kill) " /sys/fs/cgroup/demo/memory.events
   ```

## The processes limit

1. Start more processes than the group allows.
   The shell reports the fork that was refused:

   <!-- verify: expect="Resource temporarily unavailable" -->

   ```bash exec target=machine
   bash -c 'echo $$ > /sys/fs/cgroup/demo/cgroup.procs; for i in $(seq 1 15); do sleep 2 & done; wait' 2>&1 | head -n 3
   ```

2. Remove the group once its processes are gone:

   ```bash exec target=machine
   sleep 3; rmdir /sys/fs/cgroup/demo && echo removed
   ```

> [!NOTE]
> `podman run --memory 20m --pids-limit 10` and `docker run --memory 20m --pids-limit 10` write the same files.
