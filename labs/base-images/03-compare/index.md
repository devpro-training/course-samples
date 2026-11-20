# Compare base images

A base image is the first line of a Dockerfile, `FROM`.
Everything the application image holds beyond the application is inherited from it: its size, its files, its tools and its vulnerabilities.

## The candidates

The images compared are the ones of the `env:` section of `lab.yaml`, from the Docker Official Images (Ubuntu, Debian, Alpine), the vendors of enterprise distributions (SUSE, Red Hat), and two minimal families (distroless, Chainguard).

1. Put their names in a variable, for this step and the next ones:

   ```bash exec target=docker
   export BASES="${UBUNTU_IMAGE} ${DEBIAN_IMAGE} ${ALPINE_IMAGE} ${BCI_BASE_IMAGE} ${BCI_MICRO_IMAGE} ${UBI_MINIMAL_IMAGE} ${UBI_MICRO_IMAGE} ${DISTROLESS_IMAGE} ${CHAINGUARD_IMAGE}" && \
   echo "export BASES=\"${BASES}\"" >> ~/.bashrc && \
   echo ${BASES} | tr " " "\n"
   ```

2. Pull them.
   No account is needed for any of them:

   <!-- verify: requires=network timeout=600 -->

   ```bash exec target=docker
   for i in ${BASES}; do docker pull -q "$i" > /dev/null; done
   ```

## Size

1. List them from the smallest to the largest:

   <!-- verify: expect="bci-micro" -->

   ```bash exec target=docker
   for i in ${BASES}; do docker image inspect "$i" --format '{{.Size}} {{index .RepoTags 0}}'; done | sort -n | awk '{printf "%7.1f MB  %s\n", $1/1000000, $2}'
   ```

   The size of a base image is paid by every image built on it, in every registry and on every node that pulls it.

## What they contain

1. Count the files of each image.
   `docker create` makes a container without starting it, and `docker export` prints its filesystem, which works for an image that has no shell:

   <!-- verify: timeout=120 expect="files  gcr.io" -->

   ```bash exec target=docker
   for i in ${BASES}; do printf '%6s files  %s\n' "$(docker export "$(docker create "$i" /unused)" | tar -t | wc -l)" "$i"; done
   ```

2. Ask each image to run a shell.
   Some have none, which leaves nothing to type commands in:

   <!-- verify: expect="no shell  gcr.io" -->

   ```bash exec target=docker
   for i in ${BASES}; do docker run --rm --entrypoint sh "$i" -c true > /dev/null 2>&1 && echo "   shell  $i" || echo "no shell  $i"; done
   ```

3. Look for a package manager in the ones that have a shell:

   <!-- verify: expect="/sbin/apk" -->

   ```bash exec target=docker
   for i in ${UBUNTU_IMAGE} ${ALPINE_IMAGE} ${BCI_BASE_IMAGE} ${UBI_MINIMAL_IMAGE} ${UBI_MICRO_IMAGE} ${BCI_MICRO_IMAGE}; do printf '%-52s' "$i"; docker run --rm --entrypoint sh "$i" -c 'for c in apt-get apk zypper microdnf rpm; do command -v $c; done' | tr "\n" " "; echo; done
   ```

   The `-micro` images have no package manager, and not even `rpm`.
   `distroless` and Chainguard `static` have no shell at all, so they cannot be asked this way.

4. The libc decides which binaries run.
   Alpine uses musl, the others of this list use glibc, so a program built on one can fail on the other:

   <!-- verify: expect="x86_64.so.1" -->

   ```bash exec target=docker
   docker run --rm --entrypoint sh "${ALPINE_IMAGE}" -c 'ls /lib/ld-musl-* /lib/libc.musl-*'
   ```

## The vendor repositories

1. SUSE's base image comes with a repository of its own, free and preconfigured, so `zypper` works with no subscription:

   <!-- verify: requires=network timeout=120 expect="SLE_BCI" -->

   ```bash exec target=docker
   docker run --rm --entrypoint zypper "${BCI_BASE_IMAGE}" lr
   ```

2. Red Hat's `ubi-minimal` has its own repositories as well, with the UBI packages only:

   <!-- verify: requires=network timeout=120 expect="ubi-10-baseos-rpms" -->

   ```bash exec target=docker
   docker run --rm --entrypoint microdnf "${UBI_MINIMAL_IMAGE}" repolist 2>&1
   ```
