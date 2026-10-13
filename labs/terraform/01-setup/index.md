<!-- include: ../../shared/setup.md -->

## On a workstation

The tools of this course are single binaries, available on every operating system.
The infrastructure managed by hand is a folder of files, so no cloud account and no container engine are needed.

System  | Command
--------|-----------------------------------------------------------------------------------------------------------------
Windows | `winget install Hashicorp.Terraform`, or the [downloads page](https://developer.hashicorp.com/terraform/install)
macOS   | `brew tap hashicorp/tap && brew install hashicorp/tap/terraform`
Linux   | the release binary, as in this step

<!-- include: ../../shared/setup-local-bin.md -->

<!-- include: ../../shared/setup-cosign.md -->

<!-- include: ../../shared/setup-terraform.md -->
