# Summary

---

## Cheat sheet

Need                  | Kernel feature       | By hand
----------------------|----------------------|----------------------------------------
Its own files         | root filesystem      | `chroot <dir> <command>`
Its own view          | namespaces           | `unshare --pid --uts --net --mount --fork <command>`
A cap on resources    | control groups       | files under `/sys/fs/cgroup/<group>/`
The namespaces of a process | `/proc`        | `readlink /proc/<pid>/ns/pid`

Tool command                  | Does
------------------------------|-----------------------------------------------
`podman build -t <name> .`    | Builds an image from a Containerfile or a Dockerfile
`podman run --rm <image>`     | Runs a container, and removes it at exit
`podman run -d --name <n> <image>` | Runs it in the background
`podman exec <n> <command>`   | Runs a command in a running container
`podman run --memory 20m --pids-limit 10 <image>` | Sets the control group

---

## To remember

- A container is a **process**, isolated by namespaces, capped by cgroups, with its own root filesystem.

- It shares the **kernel** of the machine: it is light, and not a security boundary as strong as a virtual machine.

- The image format and the runtime are **open standards**: Docker, Podman, containerd and Kubernetes run the same images.

- A container is **disposable**: what matters is in the image, a volume or a repository.

---

## Next

- Docker: Docker Engine, images, Dockerfile, volumes, networks and Compose.

- Container base images: the image a Dockerfile starts from decides its size, its security and who it depends on.

- Further reading: [OCI](https://opencontainers.org/), [Podman](https://podman.io/docs), the manual pages `namespaces(7)` and `cgroups(7)`, and [Docker overview](https://docs.docker.com/get-started/docker-overview/).
