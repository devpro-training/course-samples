<!-- include: ../../shared/setup.md -->

## On a workstation

The tools of this course are single binaries, available on every operating system.
The environment built by hand is a folder, so no cloud account and no container engine are needed.

System         | Command
---------------|-----------------------------------------------------
Windows        | `winget install Sigstore.Cosign`, and Trivy from its [release page](https://github.com/aquasecurity/trivy/releases)
macOS          | `brew install cosign trivy`
Linux          | the release binaries, as in this step

<!-- include: ../../shared/setup-local-bin.md -->

<!-- include: ../../shared/setup-cosign.md -->

<!-- include: ../../shared/setup-trivy.md -->
