# Filter the system calls

## The risk

A container shares the kernel, and a process reaches the kernel through system calls, over three hundred of them.
Most applications use a few dozen, and a flaw in a rarely used call is a way out of the container, which the runtimes themselves have had: runc, the runtime under Docker and Kubernetes, fixed three escapes in November 2025 (CVE-2025-31133, CVE-2025-52565 and CVE-2025-52881, in runc 1.2.8, 1.3.3 and 1.4.0-rc.3).

## The logic

**seccomp** is a feature of the Linux kernel: a process gets a filter, and the kernel applies it to each call before running it.
Docker applies a default profile to every container.
It is an allow list, which refuses with an error everything it does not name, and it disables about 44 of the 300 calls and more, among them `mount`, `bpf`, `ptrace` and `reboot`, and the creation of a user namespace is refused to a container without `CAP_SYS_ADMIN`.

## The default profile

1. The engine says it has one, and a container shows the filter:

   <!-- verify: expect="name=seccomp,profile=builtin" -->

   ```bash exec target=docker
   docker info --format '{{.SecurityOptions}}'
   ```

2. `unshare --user` creates a user namespace, the first step of many escapes, and the filter refuses it:

   <!-- verify: requires=network timeout=60 expect="Operation not permitted" -->

   ```bash exec target=docker
   { docker run --rm "${ALPINE_IMAGE}" unshare --user true || true; }
   ```

3. The same container without the filter:

   <!-- verify: expect="exit 0" -->

   ```bash exec target=docker
   docker run --rm --security-opt seccomp=unconfined "${ALPINE_IMAGE}" unshare --user true; echo "exit $?"
   ```

   A profile is not a replacement of the capabilities: the two work together, each one denies what the other allows.

## A profile of the team

1. A profile is a JSON file.
   This one allows everything and refuses the creation of a directory, to show what a profile looks like:

   ```bash exec target=docker
   mkdir -p ~/lab/seccomp && cd ~/lab/seccomp && \
   tee deny-mkdir.json <<EOT
   {
     "defaultAction": "SCMP_ACT_ALLOW",
     "syscalls": [
       { "names": ["mkdir", "mkdirat"], "action": "SCMP_ACT_ERRNO" }
     ]
   }
   EOT
   ```

2. The container cannot create a directory:

   <!-- verify: expect="Operation not permitted" -->

   ```bash exec target=docker
   cd ~/lab/seccomp && \
   { docker run --rm --security-opt seccomp=deny-mkdir.json "${ALPINE_IMAGE}" mkdir /tmp/x || true; }
   ```

3. The same container with the default profile can:

   <!-- verify: expect="exit 0" -->

   ```bash exec target=docker
   docker run --rm "${ALPINE_IMAGE}" mkdir /tmp/x; echo "exit $?"
   ```

   A profile that denies a few calls is a weak one, since anything not named stays allowed.
   A strong one starts from the default `SCMP_ACT_ERRNO` and names what the application uses, which is a list to produce by tracing the application, and to maintain with it.

## What `--privileged` removes

1. `--privileged` gives all the capabilities, all the devices of the host, and removes the seccomp profile:

   <!-- verify: expect="mounted: 1" -->

   ```bash exec target=docker
   docker run --rm --privileged "${ALPINE_IMAGE}" sh -c 'echo "mounted: $(mount -t tmpfs none /mnt && grep -c " /mnt " /proc/mounts)"'
   ```

2. Without it, the same command is refused, and giving only `SYS_ADMIN` allows it too, since the default profile adapts to the capabilities that are added:

   <!-- verify: expect="mount: permission denied" -->

   ```bash exec target=docker
   { docker run --rm "${ALPINE_IMAGE}" mount -t tmpfs none /mnt || true; }
   ```

   `--privileged` is the one option to refuse in a review: a container started with it has the same rights as a process of the host.
   The documentation of Docker advises `--cap-add` of the one capability needed instead, `NET_ADMIN` for a network tool for example.

## The limits

Control                    | Where it comes from        | Limit
---------------------------|----------------------------|----------------------------------------------------
seccomp                    | the Linux kernel, in Docker, Podman, containerd | a profile of the team is a file to maintain with the application
AppArmor                   | Debian, Ubuntu and SUSE kernels | profiles are written in its own language, and do not exist on a Red Hat kernel
SELinux                    | Red Hat, Fedora kernels    | labels and policies of its own, with a policy package per container engine
A sandboxed runtime, gVisor or Kata Containers | a second boundary between the application and the host kernel | gVisor implements part of the Linux interface, so some applications fail and calls cost more, Kata starts a virtual machine, which needs virtualization on the host

- **Check what runs**: Docker enables AppArmor or SELinux when the kernel has it, and a lab or a workstation often runs without one, which `docker info` shows under `Security Options`.

- **In Kubernetes**, a pod has no seccomp profile unless it asks for `RuntimeDefault`, or the kubelet is started with `seccompDefault`: the protection of this step is not automatic there.

- **A gap stays**: a filter lowers the chance that a flaw in the kernel is reachable, and the kernel and the runtime still have to be updated.
