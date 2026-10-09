# Services with systemd

A **service** is a process that runs in the background, such as a web server or a database.
On Debian, Ubuntu, Fedora, RHEL and SUSE, the first process started by the kernel, number 1, is **systemd**, which starts the others, restarts them when they stop, and collects their output.
It reads **unit files**, which say what to run and what it depends on.

> [!NOTE]
> This virtual machine runs no init system, so `systemctl` cannot start anything here.
> The step writes a unit file, which systemd checks without running it, and the commands that manage a service are given for a machine that runs systemd.

## The machine

1. The package is there, since Debian carries it, but it is not process number 1:

   <!-- verify: expect="systemd 252" -->

   ```bash exec target=linux
   systemctl --version | head -n 1 && \
   ps -p 1 -o pid,comm
   ```

2. `systemctl` says so:

   <!-- verify: expect="has not been booted with systemd" -->

   ```bash exec target=linux
   { systemctl status || true; } 2>&1 | head -n 2
   ```

## A unit

1. Write a service that prints the date.
   `ExecStart` is the command, with its absolute path, and `WantedBy` is the target that starts it when the machine boots:

   <!-- verify: expect="9 /etc/systemd/system/hello.service" -->

   ```bash exec target=linux
   tee /etc/systemd/system/hello.service <<'EOT'
   [Unit]
   Description=Print the date

   [Service]
   Type=oneshot
   ExecStart=/usr/bin/date

   [Install]
   WantedBy=multi-user.target
   EOT
   wc -l /etc/systemd/system/hello.service
   ```

2. Check it.
   No output means that the file is correct:

   <!-- verify: expect="verify status 0" -->

   ```bash exec target=linux
   systemd-analyze verify /etc/systemd/system/hello.service ; \
   echo "verify status $?"
   ```

3. A mistake is reported.
   The command is expected to fail, since the program does not exist:

   <!-- verify: expect="not executable" -->

   ```bash exec target=linux
   sed 's#/usr/bin/date#/usr/bin/nothing#' /etc/systemd/system/hello.service > /etc/systemd/system/broken.service && \
   { systemd-analyze verify /etc/systemd/system/broken.service 2>&1 || true; }
   ```

## On a machine with systemd

Command                              | Does
-------------------------------------|--------------------------------------------------
`systemctl daemon-reload`            | Read the unit files again
`systemctl start hello`              | Start the service now
`systemctl stop hello`               | Stop it
`systemctl restart hello`            | Stop it and start it again
`systemctl status hello`             | Show its state and its last log lines
`systemctl enable hello`             | Start it at every boot
`systemctl enable --now hello`       | Enable it and start it
`systemctl list-units --type=service`| List the services
`journalctl -u hello`                | Read the log of the service
`journalctl -u hello -f`             | Follow it

> [!TIP]
> A package that ships a service, such as `nginx` or `openssh-server`, starts and enables it when it is installed on a machine with systemd.
