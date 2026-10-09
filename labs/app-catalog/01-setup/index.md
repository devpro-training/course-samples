<!-- include: ../../shared/setup.md -->

## On a workstation

The four tools of this course are single binaries, available on every operating system.
No container engine is needed: they talk to the registries directly.

System         | Command
---------------|-----------------------------------------------------
Windows        | `winget install jqlang.jq Helm.Helm Sigstore.Cosign`, and crane from its [release page](https://github.com/google/go-containerregistry/releases)
macOS          | `brew install jq crane cosign helm`
Linux          | the release binaries, as in this step

<!-- include: ../../shared/setup-local-bin.md -->

<!-- include: ../../shared/setup-jq.md -->

<!-- include: ../../shared/setup-crane.md -->

<!-- include: ../../shared/setup-cosign.md -->

<!-- include: ../../shared/setup-helm.md -->
