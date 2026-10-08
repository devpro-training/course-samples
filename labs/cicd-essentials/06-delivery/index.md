# Delivery

Continuous delivery starts from the artifact of the pipeline.
It is built once, then **deployed as it is**: the file tested by the pipeline is the file that runs, never a new build.

## The deploy script

1. Write `ci/deploy.sh`, which does four things:
   it unpacks the artifact as a **release**, in a folder of its own,
   runs a **smoke test** on it,
   then switches the `current` link to it.
   A release that fails its smoke test is never linked:

   ```bash exec
   cd ~/lab/hello && \
   cat > ci/deploy.sh <<'EOT'
   #!/usr/bin/env bash
   # Deploys an artifact built by the pipeline: unpack it as a release, smoke test it, then switch `current` to it.
   set -euo pipefail
   artifact="$1"
   root="${DEPLOY_ROOT:-$HOME/lab/deploy}"
   release="$(basename "${artifact}" .tar.gz)"

   mkdir -p "${root}/releases/${release}"
   tar -xzf "${artifact}" -C "${root}/releases/${release}"
   python3 "${root}/releases/${release}/hello.py" Smoke | grep -q "Smoke"
   ln -sfn "releases/${release}" "${root}/current.new"
   mv -T "${root}/current.new" "${root}/current"
   echo "current -> ${release}"
   EOT
   ```

   [Open deploy.sh](:open:hello/ci/deploy.sh).
   `mv -T` replaces the link in one step, so a request never finds a missing `current`.

## Deploy

1. Deploy the artifact of the first commit, which is `HEAD~2`, and run what `current` points to:

   <!-- verify: expect="current -> hello-" -->

   ```bash exec
   cd ~/lab/hello && \
   bash ci/deploy.sh ~/lab/ci/artifacts/hello-$(git rev-parse --short=7 HEAD~2).tar.gz
   ```

   <!-- verify: expect="Hello, Ada!" -->

   ```bash exec
   python3 ~/lab/deploy/current/hello.py Ada
   ```

2. Deploy the last one, the same way, and the greeting changes:

   <!-- verify: expect="Welcome, Ada!" -->

   ```bash exec
   cd ~/lab/hello && \
   bash ci/deploy.sh ~/lab/ci/artifacts/hello-$(git rev-parse --short=7 HEAD).tar.gz && \
   python3 ~/lab/deploy/current/hello.py Ada
   ```

3. Both releases are on disk, and `current` is a link to one of them:

   <!-- verify: expect="current -> releases/hello-" -->

   ```bash exec
   ls -l ~/lab/deploy ~/lab/deploy/releases
   ```

## Roll back

A rollback is a deployment of the previous artifact: no rebuild, no code change, and seconds to do.
It works because every artifact is kept, and because a release is a folder of its own.

1. Deploy the first artifact again, since the last one is wrong:

   <!-- verify: expect="Hello, Ada!" -->

   ```bash exec
   cd ~/lab/hello && \
   bash ci/deploy.sh ~/lab/ci/artifacts/hello-$(git rev-parse --short=7 HEAD~2).tar.gz && \
   python3 ~/lab/deploy/current/hello.py Ada
   ```

> [!NOTE]
> This is **continuous delivery**: a human chose to run `deploy.sh`.
> Calling it at the end of the hook, when the pipeline is green, would make it **continuous deployment**.
> A real deployment copies to a server, a registry or a cluster, but the shape stays: one artifact, immutable releases, a smoke test, a switch.
