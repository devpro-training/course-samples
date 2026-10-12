# SBOM

A software bill of materials (SBOM) lists what a project or an image is made of: each component, its version and where it comes from.
Trivy writes one in CycloneDX or SPDX, and reads one as a target.

## Generate

1. Write the SBOM of the project of the previous step, in CycloneDX, and of an image:

   <!-- verify: requires=network timeout=240 expect="app: 3 components" -->

   ```bash exec
   cd ~/lab && \
   trivy fs --no-progress --scanners vuln --format cyclonedx --output app.cdx.json app > /dev/null 2>&1 && \
   trivy image --no-progress --format cyclonedx --output alpine.cdx.json "${ALPINE_IMAGE}" > /dev/null 2>&1 && \
   for sbom in app alpine; do echo "${sbom}: $(jq '.components | length' ${sbom}.cdx.json) components"; done
   ```

   [Open app.cdx.json](:open:app.cdx.json)

2. List the components of the project:

   <!-- verify: expect="pyyaml" -->

   ```bash exec
   cd ~/lab && \
   jq -r '.components[] | select(.type == "library") | "\(.name) \(.version)"' app.cdx.json
   ```

## Scan later

A scan reads an SBOM instead of the image or the folder: the artifact is not needed, and the database is today's.

1. Scan the SBOM of the project:

   <!-- verify: expect="UNKNOWN:" -->

   ```bash exec
   cd ~/lab && \
   trivy sbom --no-progress app.cdx.json 2>&1 | grep -E "CVE-2020-14343|Total"
   ```

   An SBOM is the evidence a team keeps for each release: a vulnerability published next year is searched in the SBOMs of the releases already shipped.

## Accept a risk

A finding the team decides to live with is recorded with a reason and an expiry date, so the decision is reviewed instead of forgotten.

1. Copy the dependencies to a folder of their own, and ignore the vulnerability until a date:

   ```bash exec
   mkdir -p ~/lab/accept && cd ~/lab/accept && \
   cp ~/lab/app/requirements.txt . && \
   printf '# Not reachable: the project never loads a YAML document from outside. Reviewed by the team, until 2027-01-01.\nCVE-2020-14343 exp:2027-01-01\n' > .trivyignore
   ```

   [Open .trivyignore](:open:accept/.trivyignore)

2. Count the reports of the vulnerability, with and without the ignore file:

   <!-- verify: expect="reported: 0" -->

   ```bash exec
   cd ~/lab/accept && \
   echo "with .trivyignore, reported: $(trivy fs --no-progress --scanners vuln --format json --quiet . | jq '[.Results[].Vulnerabilities[]? | select(.VulnerabilityID == "CVE-2020-14343")] | length')" && \
   echo "without it, reported: $(trivy fs --no-progress --scanners vuln --format json --quiet --ignorefile /dev/null . | jq '[.Results[].Vulnerabilities[]? | select(.VulnerabilityID == "CVE-2020-14343")] | length')"
   ```

   The file says that a person decided, which a VEX document says in a standard format: it states whether a product is affected by a vulnerability, and Trivy reads it with `--vex`.
