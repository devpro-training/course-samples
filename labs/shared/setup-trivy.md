## Trivy

[Trivy](https://trivy.dev/) is an open source scanner of Aqua Security, a single binary.
It is installed from its release archive, checked twice: against the checksums of the release, and against the signature that GitHub's release workflow made, with the cosign installed above.

> [!NOTE]
> The binary is preferred to the container image and to the `aquasecurity/trivy-action` GitHub Action.
> On 19 March 2026 a malicious Trivy v0.69.4 was published, and 76 of the 77 version tags of the action were moved to malicious commits.
> A pinned version, a checksum and a signature are checked here by the learner, and no tag is trusted.

1. Download the archive, its signature bundle and the checksums of the release, and check the checksum:

   <!-- verify: requires=network timeout=180 expect="_Linux-64bit.tar.gz: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
     "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz.sigstore.json" \
     "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_checksums.txt" && \
   sha256sum --check --ignore-missing "trivy_${TRIVY_VERSION}_checksums.txt"
   ```

2. Verify the signature: the archive must come from the release workflow of the Trivy repository, at the tag of this version:

   <!-- verify: expect="Verified OK" -->

   ```bash exec
   cd ~ && \
   cosign verify-blob "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
     --bundle "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz.sigstore.json" \
     --certificate-oidc-issuer "${GITHUB_OIDC_ISSUER}" \
     --certificate-identity "${TRIVY_SIGNER}@refs/tags/v${TRIVY_VERSION}"
   ```

3. Install the binary, and check the version:

   <!-- verify: expect="Version: 0." -->

   ```bash exec
   cd ~ && \
   tar -xzf "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" -C ~/.local/bin trivy && \
   rm "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" "trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz.sigstore.json" "trivy_${TRIVY_VERSION}_checksums.txt" && \
   trivy version
   ```
