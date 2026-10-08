# A CI server

Continuous integration means the pipeline runs on **every push**, on a machine that is not the author's.
Git can already do it: a **hook** is a script a repository runs on an event, and `post-receive` runs on the server after a push is accepted.
It is what a CI service does when it receives a webhook, without the web interface.

## The server

1. Create a bare repository, the one a server holds, and the `post-receive` hook.
   For each pushed branch it takes the new commit, unpacks it in a clean folder, and runs the pipeline there:

   ```bash exec
   mkdir -p ~/lab/server ~/lab/ci && \
   git init --bare ~/lab/server/hello.git && \
   cat > ~/lab/server/hello.git/hooks/post-receive <<'EOT'
   #!/usr/bin/env bash
   # Runs on the server after every push, as a CI service reacts to a webhook.
   ci="$HOME/lab/ci"
   while read -r old new ref; do
     [ "${ref}" = refs/heads/main ] || continue
     short="${new:0:7}"
     work="${ci}/work/${short}"
     mkdir -p "${work}" "${ci}/runs" "${ci}/artifacts"
     git archive "${new}" | tar -x -C "${work}"
     echo "pipeline ${short}"
     (cd "${work}" && COMMIT="${new}" bash ci/pipeline.sh) 2>&1 | tee "${ci}/runs/${short}.log"
     if [ "${PIPESTATUS[0]}" -eq 0 ]; then
       cp "${work}"/dist/*.tar.gz "${ci}/artifacts/"
       echo "pipeline ${short} PASSED"
     else
       echo "pipeline ${short} FAILED"
     fi
   done
   EOT
   chmod +x ~/lab/server/hello.git/hooks/post-receive
   ```

   [Open post-receive](:open:server/hello.git/hooks/post-receive).

   Step                         | Why
   -----------------------------|----------------------------------------------------------------
   `git archive` into a new folder | The pipeline sees the pushed commit and nothing else: no file left over from a developer's machine
   `tee` into `runs/`           | The output is kept, and also sent back to the person who pushed
   `cp` into `artifacts/`       | Only a green run publishes an artifact

## Green

1. Commit the project and push it to the server.
   Every line starting with `remote:` is the output of the hook:

   <!-- verify: expect="PASSED" -->

   ```bash exec
   cd ~/lab/hello && \
   git add . && \
   git commit -m "Add hello" && \
   git remote add origin "$HOME/lab/server/hello.git" && \
   git push -u origin main
   ```

2. The pipeline published its artifact, named after the commit:

   <!-- verify: expect="hello-" -->

   ```bash exec
   ls ~/lab/ci/artifacts
   ```

## Red

1. Change the greeting without the test: a developer's mistake, pushed.

   <!-- verify: expect="FAILED" -->

   ```bash exec
   cd ~/lab/hello && \
   sed -i 's/Hello, /Hi, /' hello.py && \
   git commit -am "Shorten the greeting" && \
   git push
   ```

2. The log of the run says which test failed, and the expected and the actual value:

   <!-- verify: expect="FAIL: test_greets_by_name" -->

   ```bash exec
   grep -h -A8 "^FAIL:" ~/lab/ci/runs/*.log
   ```

3. No artifact was published for the red commit, so it can not be deployed: there is still only the first one.

   <!-- verify: expect="artifacts: 1" -->

   ```bash exec
   echo "artifacts: $(ls ~/lab/ci/artifacts | wc -l)"
   ```

## Fixed

1. The change was wanted, so the test follows it, with a new greeting.
   Fixing the build is the first priority of the team:

   <!-- verify: expect="PASSED" -->

   ```bash exec
   cd ~/lab/hello && \
   sed -i 's/Hi, /Welcome, /' hello.py && \
   sed -i 's/Hello, Ada!/Welcome, Ada!/' test_hello.py && \
   git commit -am "Welcome the user" && \
   git push
   ```

> [!NOTE]
> A hook runs after the push, so it can not refuse it: the commit is on the server whatever the result.
> A hosted service behaves the same way, and a **branch protection** rule, which requires a green pipeline before a merge, is what keeps a red commit out of the mainline.
