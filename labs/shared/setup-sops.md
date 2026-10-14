## age and SOPS

[age](https://github.com/FiloSottile/age) makes and uses small encryption keys, and [SOPS](https://getsops.io/) encrypts the values of a YAML file with them and leaves its keys readable.
`age` is a Debian package, which `apt` checks.
SOPS is a single binary, and its release publishes the checksums of its files, so the download is compared with them before it is installed.

1. Install `age` with the packages of the machine:

   <!-- verify: requires=network timeout=180 expect="/usr/bin/age-keygen" -->

   ```bash exec target=docker
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-get install -y -qq age > /dev/null 2>&1 ; \
   command -v age-keygen
   ```

2. Download the binary of SOPS and the list of checksums, check it, and install it:

   <!-- verify: requires=network timeout=120 expect="linux.amd64: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${SOPS_URL}/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64" "${SOPS_URL}/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.txt" && \
   grep " sops-${SOPS_VERSION}.linux.amd64$" "sops-${SOPS_VERSION}.checksums.txt" | sha256sum --check && \
   install -m 0755 "sops-${SOPS_VERSION}.linux.amd64" /usr/local/bin/sops && \
   rm "sops-${SOPS_VERSION}.linux.amd64" "sops-${SOPS_VERSION}.checksums.txt"
   ```

3. Check the versions:

   <!-- verify: expect="sops 3." -->

   ```bash exec target=docker
   sops --version --disable-version-check
   ```
