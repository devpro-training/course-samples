# The pipeline

The commands of the previous step, written once in a script that any machine can run: `ci/pipeline.sh`.
A CI service only calls it, so the same script is run by a developer, by a Git hook and by a hosted service.

## The script

1. Write one function per stage: lint, test and package.
   `set -e` ends the script at the first command that fails, and its exit code is what a CI service reads as red:

   ```bash exec
   cd ~/lab/hello && \
   cat > ci/pipeline.sh <<'EOT'
   #!/usr/bin/env bash
   # One function per stage, so a CI service can run them as separate steps, and a developer can run any of them.
   set -euo pipefail
   export PYTHONDONTWRITEBYTECODE=1

   version="${COMMIT:-local}"
   version="${version:0:7}"

   lint() { python3 -m py_compile hello.py test_hello.py; }
   test() { python3 -m unittest -v; }
   package() { mkdir -p dist && tar -czf "dist/hello-${version}.tar.gz" hello.py; }

   stages=("$@")
   [ ${#stages[@]} -gt 0 ] || stages=(lint test package)
   for stage in "${stages[@]}"; do
     echo "== ${stage}"
     "${stage}"
   done
   echo "== done"
   EOT
   ```

   [Open pipeline.sh](:open:hello/ci/pipeline.sh).
   The artifact is named after the commit, `COMMIT`, which the CI server provides: the file says which source it was built from.

2. Run every stage:

   <!-- verify: expect="== done" -->

   ```bash exec
   cd ~/lab/hello && \
   bash ci/pipeline.sh
   ```

3. The result is an **artifact**: a file that is built once and then deployed as it is.

   <!-- verify: expect="hello-local.tar.gz" -->

   ```bash exec
   cd ~/lab/hello && \
   ls dist
   ```

4. A stage can also be run alone, which is how a service shows one step per stage:

   <!-- verify: expect="== lint" -->

   ```bash exec
   cd ~/lab/hello && \
   bash ci/pipeline.sh lint
   ```

## Red

A pipeline is red when a command exits with a code other than 0.

1. Add a syntax error, run the lint stage and print its exit code, then remove the error:

   <!-- verify: expect="exit code: 1" -->

   ```bash exec
   cd ~/lab/hello && \
   echo "def broken(" >> hello.py && \
   { bash ci/pipeline.sh lint; echo "exit code: $?"; } ; \
   sed -i '$d' hello.py
   ```

   The error is named with its line, and the script stopped before the test stage.
   Nothing else is needed: a CI service reads the exit code, and shows the output.
