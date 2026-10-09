# Bitnami

Bitnami packaged open source applications as images and Helm charts for years, free and with versioned tags, and many charts of other projects depend on them.
VMware bought Bitnami in 2019, and Broadcom bought VMware in 2023.
On 28 August 2025, the catalog changed, as its [announcement](https://github.com/bitnami/containers/issues/83267) says:

- the images, "including older or versioned tags", moved from `docker.io/bitnami` to `docker.io/bitnamilegacy`, which "will receive no further updates or support";
- `docker.io/bitnami` keeps a "limited subset of free, latest-version images intended for development use", on the `latest` tag only;
- versioned and maintained images are part of a paid offer, Bitnami Secure Images;
- the sources of the images and charts stay on GitHub, under the Apache 2 licence.

## The images

1. List the tags of the image that the charts use, without the ones that hold signatures and attestations:

   <!-- verify: requires=network timeout=60 expect="latest" -->

   ```bash exec
   crane ls "${BITNAMI_IMAGE}" | grep -v '^sha256-'
   ```

   One tag: a build that is pinned to a version of PostgreSQL is not possible with the free images.

2. Read the last update of the legacy repository:

   <!-- verify: requires=network timeout=60 expect="last update: 2025-08-" -->

   ```bash exec
   wget -qO- "${DOCKER_HUB_API}/namespaces/bitnamilegacy/repositories/postgresql/tags?page_size=1&ordering=last_updated" | \
   jq -r '"tags: \(.count)", "last update: \(.results[0].last_updated)"'
   ```

   Thousands of tags, frozen since August 2025: every vulnerability found since then stays in them.

## A chart that still installs

A chart pins images by tag, and the tag has to exist when the chart is installed, not only when it was released.

1. Render the last chart released before the change, with no cluster, and keep the images it would run:

   <!-- verify: requires=network timeout=120 expect="image: docker.io/bitnami/postgresql:17" -->

   ```bash exec
   mkdir -p ~/lab/bitnami && cd ~/lab/bitnami && \
   helm template db "${BITNAMI_CHART}" --version "${BITNAMI_CHART_OLD}" 2> /dev/null | grep 'image:' | sort -u | tee old-images.txt
   ```

2. Ask the registry for that image:

   <!-- verify: requires=network timeout=60 expect="MANIFEST_UNKNOWN" -->

   ```bash exec
   cd ~/lab/bitnami && \
   image=$(awk '{print $2}' old-images.txt) && \
   { crane digest "${image}" 2>&1 || true; }
   ```

   The chart is still in the registry, and installs, and its pods never start: the image is gone.
   The same tag is in the legacy repository, frozen:

   <!-- verify: requires=network timeout=60 expect="sha256:" -->

   ```bash exec
   cd ~/lab/bitnami && \
   image=$(awk '{print $2}' old-images.txt) && \
   crane digest "${BITNAMI_LEGACY_IMAGE}:${image##*:}"
   ```

## The current chart

1. Render the current chart:

   <!-- verify: requires=network timeout=120 expect="bitnami/postgresql:latest" -->

   ```bash exec
   cd ~/lab/bitnami && \
   helm template db "${BITNAMI_CHART}" --version "${BITNAMI_CHART_NEW}" 2> /dev/null | grep 'image:' | sort -u
   ```

   The chart has a version, and the image it runs has none: two installs of the same chart, a week apart, can run two different PostgreSQL.

## The Linux behind it

1. Compare the base image declared by the last legacy image and by the current one.
   The labels of an image are in its configuration, read with no download of its layers:

   <!-- verify: requires=network timeout=120 expect="photon" -->

   ```bash exec
   cd ~/lab/bitnami && \
   image=$(awk '{print $2}' old-images.txt) && \
   for i in "${BITNAMI_LEGACY_IMAGE}:${image##*:}" "${BITNAMI_IMAGE}:latest"; do
     crane config --platform linux/amd64 "$i" | \
     jq -r --arg i "$i" '"\($i)\n  base: \(.config.Labels["org.opencontainers.image.base.name"])\n  vendor: \(.config.Labels["org.opencontainers.image.vendor"])"'
   done
   ```

   The legacy images were built on `minideb`, Bitnami's minimal Debian.
   The current ones are built on Photon OS, VMware's own distribution: a change of Linux under the same image name, decided by the publisher.

> [!NOTE]
> A team that stays on the legacy images, overrides the chart to point to them, or uses `latest` in production, keeps running what nobody patches.
> The ways out are the paid offer, another catalog, or building the images from the sources that stay open.
