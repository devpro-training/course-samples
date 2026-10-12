# Imperative

The environment of this course is a folder, `~/lab/env`, with a configuration file and a web page.
A first script builds it with commands, in order, the way most people start.

## A script

1. Create the script:

   ```bash exec
   mkdir -p ~/lab/imperative && cd ~/lab/imperative && \
   cat > provision.sh <<'SCRIPT'
   #!/bin/bash
   mkdir ~/lab/env
   echo "port=8080" >> ~/lab/env/app.conf
   echo "<h1>Hello</h1>" > ~/lab/env/index.html
   chmod 640 ~/lab/env/app.conf
   SCRIPT
   ```

   [Open provision.sh](:open:imperative/provision.sh)

2. Run it, and read the result:

   <!-- verify: expect="port=8080" -->

   ```bash exec
   cd ~/lab/imperative && \
   bash provision.sh; \
   echo "status $?"; \
   cat ~/lab/env/app.conf
   ```

## Run it again

1. The same script, a second time, because a deployment is run more than once:

   <!-- verify: expect="File exists" -->

   ```bash exec
   cd ~/lab/imperative && \
   bash provision.sh; \
   echo "status $?"
   ```

   `mkdir` fails, and the script still reports a success: the status is the one of its last command, `chmod`.

2. Count the lines of the configuration file:

   <!-- verify: expect="2 app.conf" -->

   ```bash exec
   cd ~/lab/env && \
   wc -l app.conf
   ```

   The line was appended again.
   The environment now holds more than the script describes, and the next run adds one more.
