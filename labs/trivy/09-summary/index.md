# Summary

---

## Cheat sheet

Command                                                          | Does
-----------------------------------------------------------------|---------------------------------------------
`trivy image <image>`                                            | scan an image of a registry
`trivy fs <folder>`                                              | scan a project: dependencies, secrets, configuration
`trivy config <folder>`                                          | the misconfigurations of Dockerfile, Kubernetes, Terraform...
`trivy sbom <file>`                                              | scan an SBOM
`--format cyclonedx --output <file>`                             | write an SBOM
`--severity HIGH,CRITICAL`                                       | filter by severity
`--ignore-unfixed`                                               | hide what has no fix yet
`--exit-code 1`                                                  | fail the job when something is found
`--scanners vuln,secret,misconfig,license`                       | choose what is looked for
`.trivyignore` with `<id> exp:<date>`                            | accept a risk until a date
`trivy version`                                                  | the version and the date of the database
`cosign verify-blob --bundle <file>.sigstore.json ...`           | verify a release of Trivy

---

## Good practices

- **Install the binary of a pinned version**, checked against a SHA-256 kept in the repository, and against its signature.
  An image or an action adds a dependency with a tag that can move.

- **Scan early and often**: the project on every change, the image on build, and again later from the SBOM, since a database gains entries every day.

- **Decide what a failure is**: a severity, a status of fix, a secret, and write it in the gate, not in a person's head.

- **Record an accepted risk** with a reason and an expiry date.

- **Read the warnings**: an end of life Linux, a severity taken from another vendor, a file that is not scanned.

- **Compare with another source**: Trivy is one tool, not the source of truth, and each way to test sees what the others do not.

---

## Further reading

- [Trivy documentation](https://trivy.dev/docs/latest/).
- [Trivy signature verification](https://trivy.dev/docs/latest/getting-started/signature-verification/).
- [Aqua Security: Trivy supply chain attack, what you need to know](https://www.aquasec.com/blog/trivy-supply-chain-attack-what-you-need-to-know), March 2026.
- [Grype](https://github.com/anchore/grype) and [OSV-Scanner](https://google.github.io/osv-scanner/).
- [CycloneDX](https://cyclonedx.org/) and [SPDX](https://spdx.dev/), the two SBOM formats.

---

## Next

- Infrastructure as Code: describe the infrastructure in files, which `trivy config` checks before anything is created.
