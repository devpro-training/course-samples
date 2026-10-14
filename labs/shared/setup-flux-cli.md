## Flux command line

`flux` is the command line of Flux, a binary of its own: it installs the controllers, and reads and asks for what they do.
Each release publishes the checksums of its archives, so the download is compared with them before it is installed.

1. Download the archive and the list of checksums, check it, and install the binary:

   <!-- verify: requires=network timeout=120 expect="linux_amd64.tar.gz: OK" -->

   ```bash exec target=docker
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${FLUXREL_URL}/${FLUXREL_VERSION}/flux_${FLUXREL_VERSION#v}_linux_amd64.tar.gz" "${FLUXREL_URL}/${FLUXREL_VERSION}/flux_${FLUXREL_VERSION#v}_checksums.txt" && \
   grep " flux_${FLUXREL_VERSION#v}_linux_amd64.tar.gz$" "flux_${FLUXREL_VERSION#v}_checksums.txt" | sha256sum --check && \
   tar -xzf "flux_${FLUXREL_VERSION#v}_linux_amd64.tar.gz" flux && \
   install -m 0755 flux /usr/local/bin/flux && \
   rm flux "flux_${FLUXREL_VERSION#v}_linux_amd64.tar.gz" "flux_${FLUXREL_VERSION#v}_checksums.txt"
   ```

2. Check the version of the client.
   The cluster is not there yet:

   <!-- verify: expect="flux version 2." -->

   ```bash exec target=docker
   flux --version
   ```
