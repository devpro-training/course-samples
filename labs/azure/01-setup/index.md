<!-- include: ../../shared/setup.md -->

## On a workstation

No Azure account is needed for this course, and none is created.
Every command reads public information, compiles or validates a file, or runs against an emulator, so nothing is deployed and nothing is billed.

Tool      | Linux                                            | macOS                                        | Windows
----------|--------------------------------------------------|----------------------------------------------|-------------------------------------------------
Azure CLI | the Microsoft package repository, `apt` or `dnf` | `brew install azure-cli`                     | `winget install --exact --id Microsoft.AzureCLI`
Bicep     | the release binary, or `az bicep install`        | `brew tap azure/bicep && brew install bicep` | `winget install -e --id Microsoft.Bicep`
Terraform | the HashiCorp repository, or the release zip     | `brew install hashicorp/tap/terraform`       | `winget install Hashicorp.Terraform`

The lab image has no administrator rights, so each tool is unpacked in the home directory instead.

<!-- include: ../../shared/setup-local-bin.md -->

<!-- include: ../../shared/setup-azure-cli.md -->

<!-- include: ../../shared/setup-bicep.md -->

<!-- include: ../../shared/setup-terraform.md -->

<!-- include: ../../shared/setup-jq.md -->

<!-- include: ../../shared/setup-npm.md -->

<!-- include: ../../shared/setup-azurite.md -->
