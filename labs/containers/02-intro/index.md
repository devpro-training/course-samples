# Containers

A process that runs isolated from the others, on the kernel of the machine.

---

## The problem

- **It works on my machine**: the application depends on a runtime, libraries and settings that differ from one machine to the next.

- **Conflicts**: two applications on one server need two versions of the same library.

- **Weight**: a virtual machine per application isolates well, and costs a whole operating system each, minutes to boot, gigabytes of disk.

- **A container** packages the application with the files it needs, and starts as a process in a second.

---

## Where it comes from

Date | Step
-----|-----------------------------------------------------------------------------------
1979 | `chroot` in Version 7 Unix: a process sees a directory as its root
2000 | FreeBSD jails: processes, users and network are isolated too
2004 | Solaris Zones
2008 | Control groups (cgroups) merged in Linux 2.6.24, and LXC builds on them
2013 | Docker: an image format and a command line that make it easy
2015 | The Open Container Initiative (OCI) standardizes the image and the runtime

- Dates differ by a year or two between sources, the order is what matters.

- References: the [OCI overview](https://opencontainers.org/about/overview/), and the manual pages `namespaces(7)` and `cgroups(7)` for the kernel.

---

## A short story

- **Unix** gave a process a smaller world: `chroot` changes what a process sees as the root of the disk, first to test builds, then to confine network services.

- **Linux** added the other pieces over the years: the **namespaces** (mount, UTS, IPC, PID, network, user, cgroup, time) to hide, and the **control groups** to cap.
  LXC was the first tool to put them together, and it needed an expert.

- **Docker** started as an internal project of dotCloud, a platform company, and was shown at PyCon in March 2013, with its code open source.
  It added what was missing: an **image** to package an application, a **registry** to share it, and a **command line** that fits in one line.

- In 2015, Docker handed its runtime code to the Open Container Initiative, which made it a standard, and the code became `runc`.

---

## And on Windows

- **Linux containers on Windows**: Docker Desktop, Podman Desktop and WSL 2 start a Linux virtual machine, and the containers run on its kernel.

- **Windows containers**: Windows Server 2016 and Windows 10 (version 1607) and later also have native containers, for Windows applications, with the same ideas.
  They run with process isolation, on the kernel of the host, or with Hyper-V isolation, in a light virtual machine.

- Reference: [About Windows containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/).

---

## What a container is

![A container is a process in its own namespaces and cgroup, on the kernel shared with the other containers and the host](../assets/containers-kernel-dark.svg#gh-dark-mode-only)
![A container is a process in its own namespaces and cgroup, on the kernel shared with the other containers and the host](../assets/containers-kernel.svg#gh-light-mode-only)

---

## Images and registries

- **An OCI image** is a manifest, a configuration (command, user, environment) and a list of layers, each a compressed archive of files.
  Any tool that follows the image specification builds or reads it: Docker, Podman, Buildah, BuildKit.

- **A registry** stores images and serves them through the OCI distribution specification: `pull` and `push` are its two verbs.

- **A name** is `registry/repository:tag`, and `@sha256:...` pins an exact content.
  When the registry is omitted, the tool uses its default, which is Docker Hub for Docker.

Registry                   | Host                   | Holds
---------------------------|------------------------|---------------------------------------------
Docker Hub                 | `docker.io`            | the Docker Official Images and the images of the community
GitHub Container Registry  | `ghcr.io`              | the images of a GitHub account or organization, next to its code
Quay                       | `quay.io`              | the images of Red Hat projects and of the community
Microsoft Artifact Registry | `mcr.microsoft.com`   | the images of .NET, SQL Server, Windows
Vendors, clouds            | `registry.suse.com`, `registry.access.redhat.com`, Azure, AWS, Google | their base images, and private images

---

## Two kernel features

- **Namespaces** limit what a process sees: its processes, hostname, network, mounts, users, IPC, cgroups and clock.

- **Control groups** limit what a process uses: memory, processes, CPU, input and output.

- **A root filesystem** gives it its own files: an image unpacked, that is `chroot` done properly.

- There is no "container" object in the kernel: the tools combine these features.

---

## Container or virtual machine

- A virtual machine runs its own kernel on virtual hardware: strong isolation, heavy.

- A container shares the kernel of the host: light, and a vulnerability of the kernel concerns every container.

- A Linux container needs a Linux kernel, which is why Windows and macOS start a Linux virtual machine behind the tool.

---

## Docker is not mandatory

- **The OCI standards**: the image format, the runtime and the distribution of images are open specifications, maintained under the Linux Foundation.

- **Docker** made the format popular, and is a standard in practice, but any tool that follows the specifications runs the same images.

- **A Dockerfile** is the recipe most tools read. The generic name is **Containerfile**, and Podman and Buildah read both.

Tool                | Role
--------------------|-------------------------------------------------------------------
Docker Engine       | daemon, build and command line, in one product
Podman and Buildah  | no daemon, rootless by default, the same commands as Docker
containerd, CRI-O   | the runtimes of Kubernetes, which removed `dockershim` in version 1.24
runc, crun          | low level runtimes that apply the namespaces and the cgroups
BuildKit            | the builder behind `docker build`

---

## In this lab

Step    | What it shows
--------|----------------------------------------------------------------------
Setup   | a virtual machine with root, busybox and Podman
Isolate | `chroot`, then `unshare`: a root filesystem, a hostname, processes, a network
Limit   | a control group that caps the memory and the processes
OCI     | a Containerfile, Podman, and the container seen as a process of the host

> The next course, Docker, installs Docker Engine and builds on this one.
