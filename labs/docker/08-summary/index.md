# Summary

---

## Cheat sheet

Command                                  | Does
-----------------------------------------|----------------------------------------------
`docker run -d --name <n> -p 8080:80 <image>` | Starts a container in the background, port published
`docker ps`, `docker ps -a`              | Running containers, all containers
`docker logs <n>`                        | The output of the container
`docker exec <n> <command>`              | Runs a command in a running container
`docker stop <n>`, `docker rm <n>`       | Stops, removes
`docker images`, `docker history <image>`| Images, their layers
`docker build -t <name>:<tag> .`         | Builds an image from a Dockerfile
`docker volume create`, `-v <vol>:<path>`| A volume, and its mount
`docker network create`                  | A network where names resolve
`docker compose up -d`, `down`           | Starts and removes the services of a file

---

## Images

- Pin the **tag** of a base image: `latest` moves.

- **Small and few**: a minimal base image, and the instructions that change the least first, so the cache works.

- One process per container, which writes its logs to the output.

- An image holds no secret: it is readable by everyone who pulls it.

---

## Containers

- A container is **disposable**: what matters is in an image, a volume or a file of a repository.

- Run it as a user that is not root when the image allows it, and publish only the ports that are needed.

- A container is isolated by the kernel, and not by a hypervisor: a vulnerability of the kernel concerns every container.

---

## Next

- Container security: what an image contains, who runs it, and what it can do.

- Trivy: scan an image for known vulnerabilities.

- Further reading: [Dockerfile reference](https://docs.docker.com/reference/dockerfile/), [Compose](https://docs.docker.com/compose/), [Build best practices](https://docs.docker.com/build/building/best-practices/) and [Docker Hub](https://hub.docker.com/).
