# Docker

Package an application with everything it needs, and run it the same way anywhere.

---

## What Docker is

- **A container** is a process that runs isolated from the others: its own filesystem, network and process list, on the kernel of the machine.

- **An image** is the read-only template a container starts from: a filesystem in layers, and the command to run.

- **Docker Engine** builds images and runs containers, on Linux.

- The isolation comes from the Linux kernel: namespaces limit what a process sees, and cgroups limit what it uses.

- Reference: [Docker overview](https://docs.docker.com/get-started/docker-overview/).

---

## Why it matters

- **Same everywhere**: the image tested on a laptop is the image run in production.

- **Light**: a container shares the kernel and starts in a second, where a virtual machine boots a whole system.

- **One artifact**: the build produces an image, the next step of a pipeline stores it and deploys it.

- **Foundation** for the registry, the scanner and the cluster that follow in this series.

---

## The parts

![The docker client sends commands to the daemon, which pulls images from a registry and runs containers from them on the Linux kernel](../assets/docker-architecture-dark.svg#gh-dark-mode-only)
![The docker client sends commands to the daemon, which pulls images from a registry and runs containers from them on the Linux kernel](../assets/docker-architecture.svg#gh-light-mode-only)

---

## Container or virtual machine

- A virtual machine runs its own kernel on virtual hardware.

- A container is a process of the host kernel, so it cannot run another kernel, and a Linux image needs a Linux kernel.

- That is why this lab runs Docker in a virtual machine, and why Docker Desktop does the same on Windows and macOS.

---

## In this lab

Step    | What it shows
--------|----------------------------------------------------------------
Setup   | Docker Engine from Docker's apt repository
Run     | `docker run`, ports, logs, `exec`, stop and remove
Images  | pull, tags, layers, and what a container writes
Build   | a Dockerfile, `docker build`, the layer cache
Data    | a volume that outlives a container, a network that resolves names
Compose | two services in one file

> A virtual machine of its own, and no account: the images come from Docker Hub, which allows anonymous pulls.
