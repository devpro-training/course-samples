# Images

An image is a stack of read-only layers and some metadata.
A container adds a thin writable layer on top, and nothing it writes changes the image.

## Pull and tags

1. The name of an image is `repository:tag`.
   Without a tag, the tag is `latest`, which moves, so a tag with a version is better:

   <!-- verify: requires=network timeout=120 -->

   ```bash exec target=docker
   docker pull "${ALPINE_IMAGE}"
   ```

2. List the images of the machine:

   <!-- verify: expect="alpine:3.22" -->

   ```bash exec target=docker
   docker images
   ```

3. A tag is only another name for an image, so one image can have several:

   <!-- verify: expect="DISK USAGE" -->

   ```bash exec target=docker
   docker tag "${ALPINE_IMAGE}" mine:1 && \
   docker images mine
   ```

## Layers

1. Every instruction of the Dockerfile that built an image made a layer, which `docker history` lists:

   <!-- verify: expect="CREATED BY" -->

   ```bash exec target=docker
   docker history "${NGINX_IMAGE}"
   ```

2. A layer is shared by the images that contain it, and stored once:

   <!-- verify: requires=network timeout=120 expect="8 layers" -->

   ```bash exec target=docker
   docker pull -q "${NGINX_IMAGE}" > /dev/null && \
   docker image inspect "${NGINX_IMAGE}" --format "{{len .RootFS.Layers}} layers"
   ```

## What a container writes

1. Create a file in a container, then ask Docker what differs from the image.
   `A` is an added file, `C` a changed directory:

   <!-- verify: expect="A /tmp/note.txt" -->

   ```bash exec target=docker
   docker run -d --name scratch "${ALPINE_IMAGE}" sleep 300 > /dev/null && \
   docker exec scratch sh -c "echo hello > /tmp/note.txt" && \
   docker diff scratch
   ```

2. The file belongs to the container, and is lost when it is removed.
   A new container from the same image starts clean:

   <!-- verify: expect="No such file" -->

   ```bash exec target=docker
   docker rm -f scratch > /dev/null && \
   { docker run --rm "${ALPINE_IMAGE}" cat /tmp/note.txt || true; }
   ```

   The command fails on purpose.
   The next step keeps data in a volume.
