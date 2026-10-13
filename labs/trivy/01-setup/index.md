<!-- include: ../../shared/setup.md -->

## On a workstation

The tools of this course are single binaries, available on every operating system.
No container engine is needed: Trivy reads an image from its registry.

System  | Command
--------|------------------------------------------------------------------------------------------------------------------------------
Windows | `winget install jqlang.jq Sigstore.Cosign`, and Trivy from its [release page](https://github.com/aquasecurity/trivy/releases)
macOS   | `brew install jq cosign trivy grype osv-scanner`
Linux   | the release binaries, as in this step

<!-- include: ../../shared/setup-local-bin.md -->

<!-- include: ../../shared/setup-jq.md -->

<!-- include: ../../shared/setup-cosign.md -->

<!-- include: ../../shared/setup-trivy.md -->
