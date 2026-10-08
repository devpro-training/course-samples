# Build an image

A `Dockerfile` lists the instructions that build an image: a base image, the files to add, the command to run.
`docker build` reads it with a build context, the folder it is run in.

## The Dockerfile

1. Write a page, and the Dockerfile that serves it with nginx:

   ```bash exec target=docker
   mkdir -p ~/lab/site && cd ~/lab/site && \
   echo "<h1>Hello from Docker</h1>" > index.html && \
   tee Dockerfile <<EOT
   FROM ${NGINX_IMAGE}
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 80
   EOT
   ```

   Instruction | Does
   ------------|----------------------------------------------------------------
   `FROM`      | the base image, pinned to a tag
   `COPY`      | adds files of the build context as a new layer
   `RUN`       | runs a command at build time, and keeps the result as a layer
   `EXPOSE`    | documents the port, without publishing it
   `CMD`       | the command a container runs, which the base image already sets here

## Build and run

1. Build the image and give it a name and a tag.
   `--progress=plain` prints every step:

   <!-- verify: timeout=120 expect="naming to docker.io/library/site:1" -->

   ```bash exec target=docker
   cd ~/lab/site && \
   docker build --progress=plain -t site:1 . 2>&1 | grep -E "^#[0-9]+ (\[|naming)"
   ```

2. Run it, and ask it:

   <!-- verify: timeout=60 expect="Hello from Docker" -->

   ```bash exec target=docker
   docker run -d --name site -p 8081:80 site:1 > /dev/null && \
   for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8081 && break; sleep 1; done
   ```

## The layer cache

Docker reuses a layer when its instruction and everything before it are unchanged.

1. Build again with the same files: every step is cached:

   <!-- verify: expect="CACHED" -->

   ```bash exec target=docker
   cd ~/lab/site && \
   docker build --progress=plain -t site:1 . 2>&1 | tail -n 14
   ```

2. Change the page, and build a second version.
   The `COPY` layer is rebuilt, and so is every layer after it, but the base image is not pulled again:

   <!-- verify: timeout=60 expect="naming to docker.io/library/site:2" -->

   ```bash exec target=docker
   cd ~/lab/site && \
   echo "<h1>Version 2</h1>" > index.html && \
   docker build --progress=plain -t site:2 . 2>&1 | tail -n 22
   ```

3. Replace the container with one from the new image:

   <!-- verify: timeout=60 expect="Version 2" -->

   ```bash exec target=docker
   docker rm -f site > /dev/null && \
   docker run -d --name site -p 8081:80 site:2 > /dev/null && \
   for i in $(seq 1 10); do wget -qO- http://127.0.0.1:8081 && break; sleep 1; done
   ```

> [!TIP]
> The instructions that change the least come first, so a change in the code rebuilds the fewest layers.
> A `.dockerignore` file keeps the files that the image does not need out of the build context.
