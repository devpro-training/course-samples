# Pipeline

A scan that nobody reads is not a control: the pipeline runs it on every change, and a status other than 0 stops the merge.
As for any pipeline of this series, the logic is in scripts of the repository, and the workflow of a service only calls them.

## Two scripts

1. Write the script that installs Trivy, and the script that decides:

   ```bash exec
   mkdir -p ~/lab/app/ci && cd ~/lab/app && \
   cat > ci/install-trivy <<'SCRIPT'
   #!/usr/bin/env bash
   # Installs the release binary of TRIVY_VERSION, after checking its SHA-256 against the one the repository pins.
   # A checksum file published beside the archive changes with it, so only a digest kept in the repository is independent of the release.
   set -euo pipefail
   : "${TRIVY_VERSION:?}" "${TRIVY_SHA256:?}"
   bin_dir="${BIN_DIR:-$HOME/.local/bin}"
   archive="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
   work="$(mktemp -d)"
   trap 'rm -rf "$work"' EXIT
   wget -q -P "$work" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${archive}"
   echo "${TRIVY_SHA256}  ${work}/${archive}" | sha256sum --check
   mkdir -p "$bin_dir"
   tar -xzf "${work}/${archive}" -C "$bin_dir" trivy
   SCRIPT
   cat > ci/scan <<'SCRIPT'
   #!/usr/bin/env bash
   # The gate: Trivy returns 1 when it finds a critical vulnerability or a secret, which fails the job.
   set -euo pipefail
   exec trivy fs --no-progress --scanners vuln,secret --severity CRITICAL --exit-code 1 "${1:-.}"
   SCRIPT
   chmod +x ci/install-trivy ci/scan
   ```

   [Open ci/install-trivy](:open:app/ci/install-trivy)
   [Open ci/scan](:open:app/ci/scan)

2. Run the install script against the digest pinned in `lab.yaml`:

   <!-- verify: requires=network timeout=180 expect="_Linux-64bit.tar.gz: OK" -->

   ```bash exec
   cd ~/lab/app && ./ci/install-trivy
   ```

3. Run it again with a digest that is not the archive's, as a tampered release would give:

   <!-- verify: requires=network timeout=180 expect="did NOT match" -->

   ```bash exec
   cd ~/lab/app && \
   { TRIVY_SHA256=0000000000000000000000000000000000000000000000000000000000000000 ./ci/install-trivy || true; }
   ```

   The script stops before the archive is unpacked.

## A failing run, and a green one

1. Run the gate on the project, which has an old PyYAML and a token:

   <!-- verify: expect="status 1" -->

   ```bash exec
   cd ~/lab/app && \
   ./ci/scan . > /dev/null 2>&1; \
   echo "status $?"
   ```

2. Fix the cause: update the two libraries, and read the token from the environment:

   ```bash exec
   cd ~/lab/app && \
   printf 'pyyaml==6.0.3\nrequests==2.33.0\n' > requirements.txt && \
   printf 'import os\n\ntoken = os.environ["TOKEN"]\n' > settings.py
   ```

   [Open requirements.txt](:open:app/requirements.txt)
   [Open settings.py](:open:app/settings.py)

3. Run the gate again:

   <!-- verify: expect="status 0" -->

   ```bash exec
   cd ~/lab/app && \
   ./ci/scan . > /dev/null 2>&1; \
   echo "status $?"
   ```

   The token of the first run is still in the history of a repository that committed it: it is revoked, not only removed.

## The workflow

1. Write the workflow of GitHub Actions that calls the two scripts:

   ```bash exec
   mkdir -p ~/lab/app/.github/workflows && cd ~/lab/app && \
   cat > .github/workflows/security.yml <<WORKFLOW
   name: Security
   on:
     pull_request:
     push:
       branches: [main]
   permissions:
     contents: read
   env:
     TRIVY_VERSION: ${TRIVY_VERSION}
     TRIVY_SHA256: ${TRIVY_SHA256}
   jobs:
     scan:
       runs-on: ubuntu-latest
       steps:
         # The commit of v6.0.3: a tag can be moved, a commit cannot.
         - uses: actions/checkout@${CHECKOUT_SHA}
           with:
             persist-credentials: false
         - name: Install Trivy from its release, checked against the pinned SHA-256
           run: ./ci/install-trivy && echo "\$HOME/.local/bin" >> "\$GITHUB_PATH"
         - name: Scan the repository
           run: ./ci/scan .
   WORKFLOW
   ```

   [Open security.yml](:open:app/.github/workflows/security.yml)

2. Count the actions the workflow uses:

   <!-- verify: expect="actions used: 1" -->

   ```bash exec
   cd ~/lab/app && \
   echo "actions used: $(grep -c 'uses:' .github/workflows/security.yml)"
   ```

   The only one is the checkout of GitHub, by commit, and Trivy is not an action.

## Why not the image or the action

Way                       | What to pin                            | What it adds to trust
--------------------------|----------------------------------------|---------------------------------------------------
Release binary            | a version and its SHA-256, a signature | one downloaded file, checked before it runs
Container image           | a digest                               | the image and its registry: Aqua flagged the Docker Hub tags 0.69.5 and 0.69.6 of March 2026
GitHub Action             | a full commit SHA                      | its code runs in the job: the malicious one read the secrets in the memory of the runner

- A tag, of an image or of an action, is moved by whoever holds the credentials of the repository.
- A digest or a commit SHA is the content, and a signature says who built it.
- The same pipeline runs on GitLab CI or Jenkins: only the file that calls the scripts changes.
