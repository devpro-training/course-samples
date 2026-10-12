## Terraform

[Terraform](https://developer.hashicorp.com/terraform) is HashiCorp's tool for infrastructure as code, a single binary.
It is installed from its release archive, checked twice: against the checksums of the release, and against the signature HashiCorp made of that checksum file, with the key whose fingerprint is published on HashiCorp's security page.

1. Download the signing key, and compare its fingerprint with the one of the security page.
   The command fails when they differ, and prints the fingerprint when they match:

   <!-- verify: requires=network timeout=60 expect="72D7 468F" -->

   ```bash exec
   cd ~ && \
   wget -q https://www.hashicorp.com/.well-known/pgp-key.txt && \
   gpg --show-keys --with-colons pgp-key.txt 2> /dev/null | grep -q "fpr:::::::::${HASHICORP_GPG_FINGERPRINT}:" && \
   gpg --show-keys --fingerprint pgp-key.txt 2> /dev/null | head -2 && \
   gpg --import pgp-key.txt 2> /dev/null
   ```

2. Download the archive, the checksums and their signature, and verify the signature:

   <!-- verify: requires=network timeout=180 expect="Good signature from" -->

   ```bash exec
   cd ~ && \
   wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
     "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
     "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" && \
   gpg --verify "terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" "terraform_${TERRAFORM_VERSION}_SHA256SUMS"
   ```

   The warning that the key is not certified is expected: the fingerprint was compared with the page of the publisher in the previous step.

3. Check the archive against the signed checksums, install the binary, and check the version:

   <!-- verify: expect="Terraform v1.16" -->

   ```bash exec
   cd ~ && \
   sha256sum --check --ignore-missing "terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
   python3 -m zipfile -e "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" ~/terraform-unpacked && \
   install -m 0755 ~/terraform-unpacked/terraform ~/.local/bin/terraform && \
   rm -rf ~/terraform-unpacked "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" "terraform_${TERRAFORM_VERSION}_SHA256SUMS" "terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" pgp-key.txt && \
   terraform version
   ```
