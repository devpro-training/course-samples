# Project

`trivy fs` scans a folder: the dependencies a lock file or a manifest names, the secrets in its files, and its configuration.
The image of a project is made of what the project declares, so a weakness is cheaper to find in the folder than in the image.

## A project

1. Create a Python project that declares two old dependencies, and a settings file with a token that looks like a GitHub one:

   ```bash exec
   mkdir -p ~/lab/app && cd ~/lab/app && \
   printf 'pyyaml==5.3.1\nrequests==2.25.0\n' > requirements.txt && \
   printf 'token = "ghp_%s"\n' "R8sT2uVwXyZ1aBcDeFgHiJkLmNoPqRsTuVwX" > settings.py
   ```

   [Open requirements.txt](:open:app/requirements.txt)
   [Open settings.py](:open:app/settings.py)

## Dependencies

1. Scan the folder for vulnerabilities and secrets:

   <!-- verify: requires=network timeout=240 expect="CVE-2020-14343" -->

   ```bash exec
   cd ~/lab/app && \
   trivy fs --no-progress --scanners vuln,secret . 2>&1 | grep -v -E "INFO|WARN"
   ```

   Each line of the first table is a library, an installed version, the version that fixes it, and a link to the advisory.
   `requirements.txt` names the two libraries, and so are the ones Trivy checks: a library they pull in is not in the file.

## A secret

The second report is the token: Trivy matches the format of well-known credentials, and hides the value in its output.

- **A secret in a commit stays in the history**, so removing the line is not enough: the credential is revoked, then replaced.
- **A match is a format**, not a proof: Trivy does not know that the token works.

## A gate

A scan is useful in a pipeline when its result decides: `--exit-code` is the status Trivy returns when it finds something, 0 by default.

1. Fail when a critical vulnerability is found:

   <!-- verify: expect="status 1" -->

   ```bash exec
   cd ~/lab/app && \
   trivy fs --no-progress --scanners vuln --severity CRITICAL --exit-code 1 requirements.txt > /dev/null 2>&1; \
   echo "status $?"
   ```

   The next steps build on this gate.
