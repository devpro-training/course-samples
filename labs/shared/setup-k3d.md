## k3d

[k3d](https://k3d.io/) is a single binary.
Each release publishes the checksums of its binaries, so the download is compared with them before it is installed.

1. Download the binary and the list of checksums, check it, and install it.
   The list names the files with the folder they were built in:

   <!-- verify: requires=network timeout=120 expect="k3d-linux-amd64: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${K3DCLI_URL}/${K3DCLI_VERSION}/k3d-linux-amd64" "${K3DCLI_URL}/${K3DCLI_VERSION}/checksums.txt" && \
   grep " _dist/k3d-linux-amd64$" checksums.txt | sed "s# _dist/# #" | sha256sum --check && \
   install -m 0755 k3d-linux-amd64 /usr/local/bin/k3d
   ```

2. Check the version.
   The binary also states the k3s version it uses when none is asked for:

   <!-- verify: expect="k3d version v5." -->

   ```bash exec target=docker
   k3d version
   ```
