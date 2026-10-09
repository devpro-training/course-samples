# The standard way

A container tool does what the previous steps did by hand, from an **image**: the root filesystem in layers, and the command to run, in the format of the OCI.
Podman is used here, since it needs no daemon, and Docker takes the same commands and the same files.

> [!NOTE]
> The kernel of the lab machine lacks a netfilter module that Podman's bridge network needs, so every container here runs with `--network none`, which gives it the loopback only, as in the previous step.
> On a workstation, the option is not needed, and the container gets a bridge network.

## A runtime

1. Podman hands the container to a low level runtime, which applies the namespaces and the control groups:

   <!-- verify: expect="crun cgroups v2" -->

   ```bash exec target=machine
   podman info --format '{{.Host.OCIRuntime.Name}} cgroups {{.Host.CgroupsVersion}}'
   ```

## A Containerfile

1. Write the recipe of an image.
   Podman reads `Containerfile`, and `Dockerfile` as well:

   ```bash exec target=machine
   mkdir -p ~/lab/app && cd ~/lab/app && \
   tee Containerfile <<EOT
   FROM ${ALPINE_IMAGE}
   RUN echo "Hello from an image" > /hello.txt
   CMD ["cat", "/hello.txt"]
   EOT
   ```

2. Build the image, then run it.
   `--rm` removes the container when it exits:

   <!-- verify: requires=network timeout=180 expect="Hello from an image" -->

   ```bash exec target=machine
   cd ~/lab/app && \
   podman build -q --network none -t hello:1 . > /dev/null && \
   podman run --rm --network none hello:1
   ```

## A process of the machine

1. Start a container in the background:

   <!-- verify: requires=network timeout=120 -->

   ```bash exec target=machine
   podman run -d --network none --name sleeper "${ALPINE_IMAGE}" sleep 300 > /dev/null
   ```

2. The machine sees it as a process like any other:

   <!-- verify: expect="sleep 300" -->

   ```bash exec target=machine
   pgrep -a sleep
   ```

3. Inside, the same process is process 1:

   <!-- verify: expect="1 root" -->

   ```bash exec target=machine
   podman exec sleeper ps
   ```

4. Its namespaces differ from the ones of the machine, as for `unshare`:

   <!-- verify: expect="pid:[" -->

   ```bash exec target=machine
   pid=$(podman inspect --format '{{.State.Pid}}' sleeper) && \
   readlink /proc/$pid/ns/pid /proc/self/ns/pid
   ```

5. A limit is a control group, set with an option:

   <!-- verify: expect="20971520" -->

   ```bash exec target=machine
   podman run --rm --network none --memory 20m "${ALPINE_IMAGE}" cat /sys/fs/cgroup/memory.max
   ```

6. Remove the container:

   ```bash exec target=machine
   podman rm -f sleeper
   ```

## Images and registries

1. The image was pulled from a registry, and its full name says which one: the registry host, the repository and the tag.
   The image built locally has no registry, so Podman names it `localhost`:

   <!-- verify: expect="docker.io/library/alpine" -->

   ```bash exec target=machine
   podman images --format '{{.Repository}}:{{.Tag}}'
   ```

2. An image is found by its content as well, with a digest, which a tag cannot change:

   <!-- verify: expect="sha256:" -->

   ```bash exec target=machine
   podman image inspect "${ALPINE_IMAGE}" --format '{{.Digest}}'
   ```

   `podman push` sends an image to a registry the same way, to `docker.io/<user>/<name>:<tag>` or `ghcr.io/<owner>/<name>:<tag>` after a `podman login`.

## The same image elsewhere

An image built by Podman or Docker follows the OCI image specification, so the same image runs with Docker, containerd, CRI-O or Kubernetes.
Only the tool that runs it changes.

Docker command           | Podman command
-------------------------|-------------------------
`docker build -t x .`    | `podman build -t x .`
`docker run --rm x`      | `podman run --rm x`
`docker ps`              | `podman ps`
`docker exec c ps`       | `podman exec c ps`
