# Trivy

An image, a project and its configuration hold more than their authors wrote: packages, libraries, a base Linux, and sometimes a secret.
A scanner lists them and compares them with what is publicly known.

---

## What Trivy is

- **An open source scanner** of Aqua Security, a single binary with no server.

- **Its targets**: container image, filesystem, root filesystem, code repository, virtual machine image, Kubernetes and SBOM.

- **Its scanners**: vulnerabilities, misconfigurations, secrets, licenses and cryptographic assets.

- **Its data**: advisories of the Linux distributions, the GitHub Advisory Database and other sources, packed as OCI artifacts in public registries and cached.

---

## How a scan works

![A target is analyzed into packages, dependencies and files, each is matched against the databases, and the report ends with an exit code](../assets/trivy-scan-dark.svg#gh-dark-mode-only)
![A target is analyzed into packages, dependencies and files, each is matched against the databases, and the report ends with an exit code](../assets/trivy-scan.svg#gh-light-mode-only)

---

## One tool among others

- **Trivy is not the source of truth.**
  It reports what its databases know about what its analyzers recognize.

- **Other scanners exist**: Grype, OSV-Scanner, Docker Scout, Snyk, the scan of a registry or of a cloud.
  They read other sources, so they find other things.

- **Other ways to test exist too**: code review and static analysis, tests of the running application, a penetration test, and runtime detection.

- **A scan finds a known weakness**, which is a part of the work: the rest is a decision about what to fix, accept or dismiss.

---

## A scanner is a dependency

- **19 March 2026**: a malicious Trivy v0.69.4 was published, and 76 of the 77 version tags of `trivy-action` were moved to malicious commits.
  Aqua's advisory names v0.35.0 of the action as the only version unaffected.

- **It ran before the legitimate scan**, so a pipeline looked normal, while it targeted the secrets of the runner.

- **A tag is a name the publisher, or an attacker, can move.**
  A checksum and a signature are not.

- **This course installs the release binary**, with a pinned version, its checksum and its signature, and runs it as a plain command, in the terminal and in a pipeline.
  A container image or a GitHub Action adds a layer that is also a dependency.

---

## In this lab

Step      | What it shows
----------|-----------------------------------------------------------------------
Setup     | cosign and Trivy, verified: checksum and signature
Image     | scan an image of a registry, severities, unfixed, an end of life Linux
Project   | the dependencies of a project, a secret, and a gate on the exit code
Config    | the misconfigurations of a Dockerfile and a Kubernetes manifest
SBOM      | generate one, scan it later, and accept a risk with an expiry date
Pipeline  | a gate in a script, a failing run, a fix, and the install in a workflow
Compare   | Grype and OSV-Scanner on the same project

> No account and no container engine: Trivy reads the registry and the files.
