# Volumes and networks

A container's filesystem is lost with it, and a container only reaches others through a network.
A volume keeps data, and a network gives names.

## A volume

1. Create a volume, and write a file to it from a container:

   <!-- verify: expect="VOLUME NAME" -->

   ```bash exec target=docker
   docker volume create data && \
   docker run --rm -v data:/data "${ALPINE_IMAGE}" sh -c "echo kept > /data/note.txt" && \
   docker volume ls
   ```

2. That container is gone, and a new one reads the file:

   <!-- verify: expect="kept" -->

   ```bash exec target=docker
   docker run --rm -v data:/data "${ALPINE_IMAGE}" cat /data/note.txt
   ```

3. Docker stores the volume on the machine, outside any container:

   <!-- verify: expect="/var/lib/docker/volumes/data/_data" -->

   ```bash exec target=docker
   docker volume inspect data --format "{{.Mountpoint}}"
   ```

> [!NOTE]
> A bind mount, `-v "$PWD":/data`, shares a folder of the machine instead, which suits source code during development.

## A network

On a network that the user creates, a container reaches another by its name.

1. Create a network, and start the server in it:

   ```bash exec target=docker
   docker network create app && \
   docker run -d --name api --network app "${NGINX_IMAGE}"
   ```

2. Another container of the network resolves `api`:

   <!-- verify: timeout=60 expect="Welcome to nginx!" -->

   ```bash exec target=docker
   docker run --rm --network app "${ALPINE_IMAGE}" wget -qO- --tries=5 http://api
   ```

3. The server published no port, so only the containers of the network reach it.
   Clean up:

   ```bash exec target=docker
   docker rm -f api site > /dev/null && \
   docker network rm app
   ```
