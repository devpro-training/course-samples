# Keep the host out of reach

## The risk

A container is isolated from the files of the host until someone gives it a path.
Two gifts are common, and both are a path to the whole machine: a **bind mount** of a directory, and the **Docker socket**.

## A bind mount

1. A file of the host, in a directory that a container will receive:

   ```bash exec target=docker
   mkdir -p ~/lab/host && cd ~/lab/host && \
   echo "payroll-2026" > secret.txt && \
   wc -l secret.txt
   ```

2. The container reads it, and writes to it, since it runs as root, the owner:

   <!-- verify: requires=network timeout=60 expect="payroll-2026" -->

   ```bash exec target=docker
   docker run --rm -v ~/lab/host:/data "${ALPINE_IMAGE}" sh -c 'cat /data/secret.txt; echo "added by a container" >> /data/secret.txt'
   ```

3. The change is on the host:

   <!-- verify: expect="2 secret.txt" -->

   ```bash exec target=docker
   cd ~/lab/host && wc -l secret.txt
   ```

4. `:ro` makes the mount read-only, and the application gets what it reads, and nothing it could damage:

   <!-- verify: expect="Read-only file system" -->

   ```bash exec target=docker
   { docker run --rm -v ~/lab/host:/data:ro "${ALPINE_IMAGE}" sh -c 'echo again >> /data/secret.txt' || true; }
   ```

   A named volume, which Docker creates and owns, is preferred to a path of the host when the data belongs to the application.
   A path that holds more than the application needs (`/`, `/etc`, a home directory) is a gift of the host.

## The Docker socket

`/var/run/docker.sock` is the API of the daemon, which runs as root.
Whoever can talk to it can ask for any container, with any option, so a container that receives the socket can create one that mounts the whole disk of the host.

1. A container with the socket and the Docker client, which asks the daemon for a second container that mounts the host's root directory, and reads the file of the host:

   <!-- verify: requires=network timeout=180 expect="payroll-2026" -->

   ```bash exec target=docker
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock "${DOCKER_CLI_IMAGE}" \
     docker run --rm -v /:/host "${ALPINE_IMAGE}" cat "/host${HOME}/lab/host/secret.txt"
   ```

   The first container had no privilege, no bind mount, and was one command from the host.

2. The rule applies to people as well: the group `docker` of a machine is root on that machine, and is given as such.
   A TCP port of the daemon without TLS is refused by the daemon itself, and SSH (`DOCKER_HOST=ssh://<user>@<host>`) is the documented alternative.

## The limits

- **Tools that need the socket**: a CI agent, a reverse proxy that discovers containers, a dashboard.
  Each one is a root on the host: a proxy of the socket that allows only a few calls, or a tool of another model (a build with no daemon, rootless Podman), reduces it.

- **Rootless mode** runs the daemon and the containers as a user that is not root, so the socket is the one of that user.
  The documentation of Docker lists what it gives up, for example no `setuid` binaries in the containers, and a setup that needs `newuidmap` and a range of numbers.

- **Podman** has no daemon, so the question of the socket is replaced by the one of a user that runs its own containers.
