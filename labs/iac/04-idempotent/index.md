# Idempotent

A command is idempotent when running it again leaves the same result.
Most of the work of an imperative script is to make each line so.

## Safe to repeat

1. Start from an empty folder, and rewrite each line to describe a result:

   ```bash exec
   rm -rf ~/lab/env && \
   cd ~/lab/imperative && \
   cat > provision.sh <<'SCRIPT'
   #!/bin/bash
   mkdir -p ~/lab/env
   printf 'port=8080\n' > ~/lab/env/app.conf
   printf '<h1>Hello</h1>\n' > ~/lab/env/index.html
   chmod 640 ~/lab/env/app.conf
   SCRIPT
   ```

   [Open provision.sh](:open:imperative/provision.sh)

   - `mkdir -p` accepts a folder that exists.
   - `printf >` replaces the file, where `echo >>` appended to it.

2. Run it twice, and take a fingerprint of the folder after each run:

   <!-- verify: expect="distinct: 1" -->

   ```bash exec
   cd ~/lab/imperative && \
   bash provision.sh && find ~/lab/env -type f | sort | xargs sha256sum | sha256sum > first.txt && \
   bash provision.sh && find ~/lab/env -type f | sort | xargs sha256sum | sha256sum > second.txt && \
   echo "distinct: $(cat first.txt second.txt | sort -u | wc -l)"
   ```

   One fingerprint: the second run changed nothing.

## What it still cannot do

1. Remove the web page from the script, and run it:

   <!-- verify: expect="files: 2" -->

   ```bash exec
   cd ~/lab/imperative && \
   sed -i '/index.html/d' provision.sh && \
   bash provision.sh && \
   echo "files: $(find ~/lab/env -type f | wc -l)"
   ```

   The page is still there: a script says what to do, so a line that is gone does nothing, not even its opposite.

2. Three limits remain, whatever the care taken on each line:

   - **No preview**: the only way to know what the script does is to run it.
   - **No removal**: what the script stops mentioning is left behind.
   - **No comparison**: a file changed by hand is overwritten, or kept, depending on the line, and nothing says which.
