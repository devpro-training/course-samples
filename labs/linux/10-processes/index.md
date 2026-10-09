# Processes

A running program is a **process**, with a number (PID), a parent, an owner and an environment.
The kernel lists them in `/proc`, and `ps` and `top` read it.

## List

1. List the processes, with their number, their parent and their owner:

   <!-- verify: expect="PID" -->

   ```bash exec target=linux
   ps -eo pid,ppid,user,comm | head -n 8
   ```

2. `top` shows them live, sorted by the CPU they use. `-b` prints one screen and exits instead of waiting for keys:

   <!-- verify: expect="load average" -->

   ```bash exec target=linux
   top -bn1 | head -n 5
   ```

## Start and stop

1. A command followed by `&` runs in the background, and `jobs` lists them:

   ```bash exec target=linux
   sleep 600 &
   ```

   <!-- verify: expect="Running" -->

   ```bash exec target=linux
   jobs && pgrep -a sleep
   ```

2. `kill` sends a signal to a process.
   The default one, `SIGTERM`, asks it to stop, and `kill -9`, `SIGKILL`, stops it without asking.
   `pkill` finds the process by its name:

   <!-- verify: expect="pgrep status 1" -->

   ```bash exec target=linux
   pkill -x sleep ; \
   sleep 1 ; \
   { pgrep -x sleep || echo "pgrep status $?"; }
   ```

## Exit status and environment

1. A command ends with an **exit status**: 0 for success, another number for a failure.
   The shell keeps the last one in `$?`, which `&&` and `||` read:

   <!-- verify: expect="exit status 2" -->

   ```bash exec target=linux
   ls /nonexistent 2> /dev/null ; \
   echo "exit status $?"
   ```

2. A process inherits the **environment variables** of its parent when they are exported:

   <!-- verify: expect="greeting: hello" -->

   ```bash exec target=linux
   GREETING=hello && \
   bash -c 'echo "not exported: $GREETING"' && \
   export GREETING && \
   bash -c 'echo "greeting: $GREETING"'
   ```

3. The shell itself is a process, and `/proc/$$` is its folder, where `$$` is its number:

   <!-- verify: expect="/bin/bash" -->

   ```bash exec target=linux
   readlink /proc/$$/exe ; \
   tr '\0' ' ' < /proc/$$/cmdline ; echo
   ```
