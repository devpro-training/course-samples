# Official images

On Docker Hub, an image under `library/`, such as `postgres`, is a Docker Official Image.
Docker sponsors a team that reviews and publishes them,
and "Docker is responsible for building and publishing the images on Docker Hub", as its [documentation](https://docs.docker.com/docker-hub/repos/manage/trusted-content/official-images/) says.
The upstream authors are preferred as maintainers, and it "isn't a strict requirement".

The questions of this course are asked to `postgres:18`: who publishes it, on which Linux, as which user, and with what evidence.

## Who publishes it

1. Read its page on Docker Hub:

   <!-- verify: requires=network timeout=60 expect="publisher: library" -->

   ```bash exec
   wget -qO- "${DOCKER_HUB_API}/repositories/library/postgres/" | \
   jq -r '"publisher: \(.namespace)", "pulls: \(.pull_count)", "last update: \(.last_updated)"'
   ```

   Billions of pulls, and a recent update: the image is used everywhere, and rebuilt often.
   Neither says who answers when it breaks: the Docker Official Images come with no support contract.

## The Linux behind it

An image is an application on a Linux distribution, and the distribution decides the packages, the patches and the lifecycle.

1. Read the distribution of the image.
   `crane export` streams its files, and `tar` keeps `os-release`, the file that names the system:

   <!-- verify: requires=network timeout=300 expect="PRETTY_NAME=" -->

   ```bash exec
   crane export --platform linux/amd64 "${OFFICIAL_IMAGE}" - | tar -xO --wildcards '*os-release' | grep -m1 '^PRETTY_NAME'
   ```

   Debian: a community distribution, with a published lifecycle.

## As which user

1. Read the configuration of the image, the user it starts as and its entry point:

   <!-- verify: requires=network timeout=60 expect="entrypoint: docker-entrypoint" -->

   ```bash exec
   crane config --platform linux/amd64 "${OFFICIAL_IMAGE}" | \
   jq -r '"user: \(.config.User // "" | if . == "" then "root, by default" else . end)", "entrypoint: \(.config.Entrypoint | join(" "))"'
   ```

   The image starts as root, and its entry point script switches to the `postgres` user with `gosu` before starting the server.
   It works, and it is a choice of the image that the team has to know: a cluster that refuses root containers refuses it.

## What proves it

1. List what is attached to the image.
   Docker's build attaches an attestation manifest to each platform, which holds documents identified by their predicate type:

   <!-- verify: requires=network timeout=60 expect="spdx.dev" -->

   ```bash exec
   att=$(crane manifest "${OFFICIAL_IMAGE}" | \
     jq -r '[.manifests[] | select(.annotations["vnd.docker.reference.type"] == "attestation-manifest")][0].digest') && \
   crane manifest "${OFFICIAL_IMAGE%:*}@${att}" | jq -r '.layers[].annotations["in-toto.io/predicate-type"]'
   ```

   An SBOM in SPDX format, and a SLSA provenance: what the image holds, and how it was built.

2. Look for a signature:

   <!-- verify: requires=network timeout=60 expect="No Supply Chain Security Related Artifacts" -->

   ```bash exec
   cosign tree "${OFFICIAL_IMAGE}" 2>&1 | head -2
   ```

   cosign finds none.
   Docker is retiring Docker Content Trust, its former signing, for the Docker Official Images, and recommends planning a move to Sigstore or Notation.
   An attestation that is not signed says what the image claims, not who claims it.

## When a publisher stops

MinIO, an object storage server, had one of the most pulled images of Docker Hub.
In October 2025, its community edition became source-only: no more images, no more binaries, at the time of a security release that fixed CVE-2025-62506.

1. Ask Docker Hub for its tags:

   <!-- verify: requires=network timeout=60 expect="authentication required" -->

   ```bash exec
   { crane ls "${MINIO_IMAGE}" 2>&1 || true; } | tail -1
   ```

   The repository is gone, and a registry answers for a repository that does not exist as for one that is private.
   Every Dockerfile, chart and pipeline that named it stopped working on the same day.

> [!NOTE]
> The story, and the alternatives compared with a scanner: [MinIO container images gone? Best alternatives](https://devpro.fr/minio-container-images-gone-best-alternatives-2025/), by Bertrand Thomas, October 2025.
