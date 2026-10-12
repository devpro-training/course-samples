## OpenTofu

[OpenTofu](https://opentofu.org/) is the open source fork of Terraform, a Linux Foundation project, with the command `tofu`.
It is installed from its release archive, checked twice: against the checksums of the release, and against the keyless signature that the release workflow made of the checksum file, with the cosign installed in the setup.

1. Download the archive, the checksums, and the signature with its certificate, and check the archive:

   <!-- verify: requires=network timeout=180 expect="_linux_amd64.zip: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip" \
     "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_SHA256SUMS" \
     "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_SHA256SUMS.pem" \
     "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_SHA256SUMS.sig" && \
   sha256sum --check --ignore-missing "tofu_${OPENTOFU_VERSION}_SHA256SUMS"
   ```

2. Verify the signature of the checksum file: it must come from the release workflow of the OpenTofu repository, on the branch of this version:

   <!-- verify: expect="Verified OK" -->

   ```bash exec
   cd ~ && \
   cosign verify-blob "tofu_${OPENTOFU_VERSION}_SHA256SUMS" \
     --signature "tofu_${OPENTOFU_VERSION}_SHA256SUMS.sig" \
     --certificate "tofu_${OPENTOFU_VERSION}_SHA256SUMS.pem" \
     --certificate-oidc-issuer "${GITHUB_OIDC_ISSUER}" \
     --certificate-identity "${OPENTOFU_SIGNER}@refs/heads/${OPENTOFU_BRANCH}" 2>&1 | grep -v deprecated
   ```

3. Install the binary, and check the version:

   <!-- verify: expect="OpenTofu v1.13" -->

   ```bash exec
   cd ~ && \
   python3 -m zipfile -e "tofu_${OPENTOFU_VERSION}_linux_amd64.zip" ~/tofu-unpacked && \
   install -m 0755 ~/tofu-unpacked/tofu ~/.local/bin/tofu && \
   rm -rf ~/tofu-unpacked "tofu_${OPENTOFU_VERSION}_linux_amd64.zip" "tofu_${OPENTOFU_VERSION}_SHA256SUMS" "tofu_${OPENTOFU_VERSION}_SHA256SUMS.pem" "tofu_${OPENTOFU_VERSION}_SHA256SUMS.sig" && \
   tofu version
   ```
