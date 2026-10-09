# Container base images

The first line of a Dockerfile, `FROM`, decides more than any other.

---

## What a base image is

- **An image is built in layers**: a Dockerfile starts `FROM` another image, and adds its own layers on top.

- **The base image** is that first image: the libc, the certificates, a shell and a package manager, or none of them.

- **Everything is inherited**: the size, the files, the vulnerabilities, the licence and the support, for every image built on it.

- **No kernel**: a container uses the kernel of its host, so a base image is a userland, and not an operating system.

---

## Why it matters

- **Security**: fewer files and fewer tools mean fewer vulnerabilities to patch and fewer tools in an attacker's hands.

- **Cost**: a smaller image is pulled faster, by every node, on every deployment.

- **Sovereignty and independence**: the base image is a supply chain. It says who builds the packages, which registry is called by every build, under which licence, and for how long.

- **Operations**: a base without a shell is harder to debug, and one with a different libc can break a binary.

---

## The families

Family                | Examples                                   | Idea
----------------------|--------------------------------------------|--------------------------------------------
Full distribution     | `ubuntu`, `debian`, `bci-base`, `ubi`      | a familiar system, with its package manager
Slim                  | `debian:slim`, `ubi-minimal`, `bci-minimal`| the distribution without its extras
Small distribution    | `alpine`, `busybox`                        | another libc (musl) and its own tools
Micro                 | `bci-micro`, `ubi-micro`                   | files and libraries, with no package manager
Distroless            | `distroless/static`, Chainguard `static`   | the files an application needs, no shell
Empty                 | `scratch`                                  | nothing at all: a static binary only

---

## Docker is not mandatory

- A **Dockerfile** is the recipe most tools read, and `docker` the command most people know. Both are a de facto standard.

- The **OCI** specifications define the image and the runtime, so any compliant tool builds and runs the same images: Podman and Buildah, BuildKit, containerd, CRI-O.

- A **Containerfile** is the same file under a neutral name, read by Podman and Buildah, and by Docker with `-f`.

- Base images are OCI images, usable with any of them. This lab uses Docker Engine since it is the common reference.

---

## In this lab

Step          | What it shows
--------------|-----------------------------------------------------------------------------------
Setup         | Docker Engine in a virtual machine
Compare       | size, files, shell, package manager and libc of nine base images
Free and enterprise | SUSE BCI, Red Hat UBI, distroless, Docker Hardened Images, Chainguard, WizOS, and what each costs
Build         | one application on seven bases, with a multi-stage Dockerfile
Best practices| layer cache, a user that is not root, a pinned digest
Improve       | what a package manager adds, and how to hold it back
Harden        | tools that remove what an application does not use

> A virtual machine of its own, and no account: every image of the lab is pulled anonymously.
