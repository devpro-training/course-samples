# Improve an image that exists

A team often starts from a large base, and a rewrite is not always possible.
What the image holds beyond what the application uses is the margin to reduce.

## What a package manager adds

1. Write three Dockerfiles that install `curl` on `debian:13-slim`:

   - `fat` installs it with the defaults, and recommended packages come with it.
   - `late` removes the package lists in a following instruction.
   - `lean` installs without the recommended packages, and removes the lists in the same instruction.

   ```bash exec target=docker
   mkdir -p ~/lab/apt && cd ~/lab/apt && \
   tee Dockerfile.fat <<EOT
   FROM ${DEBIAN_IMAGE}
   RUN apt-get update && apt-get install -y curl
   EOT
   tee Dockerfile.late <<EOT
   FROM ${DEBIAN_IMAGE}
   RUN apt-get update && apt-get install -y curl
   RUN rm -rf /var/lib/apt/lists/*
   EOT
   tee Dockerfile.lean <<EOT
   FROM ${DEBIAN_IMAGE}
   RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
   EOT
   ```

2. Build them, and compare with the base:

   <!-- verify: requires=network timeout=600 expect="MB  apt:lean" -->

   ```bash exec target=docker
   cd ~/lab/apt && \
   for v in fat late lean; do docker build -q -f Dockerfile.$v -t apt:$v . > /dev/null; done && \
   for i in ${DEBIAN_IMAGE} apt:fat apt:late apt:lean; do docker image inspect "$i" --format '{{.Size}} {{index .RepoTags 0}}'; done | awk '{printf "%7.1f MB  %s\n", $1/1000000, $2}'
   ```

   A layer is never smaller than what it adds: `late` removes files in a new layer, and the old layer still holds them.
   A deletion has to be in the instruction that created the files.

## What the layers say

1. `docker history` lists the layers and the instruction of each, with its size:

   <!-- verify: expect="--no-install-recommends" -->

   ```bash exec target=docker
   docker history --no-trunc apt:lean --format '{{.Size}}\t{{.CreatedBy}}' | cut -c1-120
   ```

## Same application, other bases

1. The cheapest improvement is often the base: the application image of the previous step, on a smaller one.
   `hello:debian` and `hello:scratch` hold the same binary:

   <!-- verify: expect="hello:debian" -->

   ```bash exec target=docker
   for t in debian scratch; do docker image inspect "hello:$t" --format '{{.Size}} {{index .RepoTags 0}}'; done | awk '{printf "%7.1f MB  %s\n", $1/1000000, $2}'
   ```

> [!NOTE]
> A scanner reads the files of these images, and counts the packages and the vulnerabilities the base brings.
> The next courses, Container security and Trivy, measure it.
