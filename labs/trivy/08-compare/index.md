# Compare

Trivy is one scanner among others, each with its own data, its own analyzers and its own rules.
Two other single binaries read the same project: Grype of Anchore, and OSV-Scanner of Google.

<!-- include: ../../shared/setup-grype.md -->

<!-- include: ../../shared/setup-osv-scanner.md -->

## The same project, three scanners

1. Create a project with the old dependencies of the beginning:

   ```bash exec
   mkdir -p ~/lab/compare && cd ~/lab/compare && \
   printf 'pyyaml==5.3.1\nrequests==2.25.0\n' > requirements.txt
   ```

2. List the packages each scanner finds vulnerable:

   <!-- verify: requires=network timeout=300 expect="urllib3" -->

   ```bash exec
   cd ~/lab/compare && \
   echo "trivy:       $(trivy fs --no-progress --scanners vuln --format json --quiet . | jq -r '[.Results[].Vulnerabilities[]?.PkgName] | unique | join(" ")')" && \
   echo "grype:       $(grype dir:. -q -o json 2>/dev/null | jq -r '[.matches[].artifact.name] | unique | join(" ")')" && \
   echo "osv-scanner: $(osv-scanner scan source -L requirements.txt --format json 2>/dev/null | jq -r '[.results[].packages[].package.name] | unique | join(" ")')"
   ```

   OSV-Scanner resolves the dependencies of the dependencies, and finds more, where the two others check the two libraries the file names.
   Its `--no-resolve` flag turns that off, and it queries the OSV service by default, where Trivy and Grype keep a database in their cache.

3. Read how each names the same weakness of PyYAML:

   <!-- verify: expect="CVE-2020-14343" -->

   ```bash exec
   cd ~/lab/compare && \
   echo "trivy: $(trivy fs --no-progress --scanners vuln --format json --quiet . | jq -r '.Results[].Vulnerabilities[]? | select(.PkgName == "pyyaml") | .VulnerabilityID')" && \
   echo "grype: $(grype dir:. -q -o json 2>/dev/null | jq -r '.matches[] | select(.artifact.name == "pyyaml") | .vulnerability.id')"
   ```

   Trivy prints the CVE, Grype the GitHub advisory (GHSA) of the same weakness: the identifiers differ, so a team compares what is found, not its names.

## Reading the differences

- **A scanner knows its sources**: the distribution advisories, the GitHub Advisory Database and the OSV database do not hold the same entries on the same day.
- **A scanner knows its analyzers**: a file format, a binary built without a package manager, or a vendored library is seen by one and not by another.
- **A finding is a candidate**: whether the code reaches the vulnerable function, and whether an attacker reaches the code, is the team's analysis.
- **No finding is not a safe verdict**: it is the absence of a known match, with these tools, on this day.

Beyond scanners, other ways to test complete the picture: a code review and static analysis of the code the team writes, the tests of the running application, a penetration test, and runtime detection of what a container really does.
