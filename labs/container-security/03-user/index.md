# Run as a user that is not root

## The risk

A container starts as root unless the image says otherwise, and its root is the root of the host as far as the kernel is concerned: same user number, same permissions on the files it can reach.
What keeps it contained is a list of **capabilities**, a split of the powers of root, that Docker trims to fourteen.

## The logic

Capability   | Allows
-------------|----------------------------------------------------
`CHOWN`      | change the owner of any file
`DAC_OVERRIDE` | ignore the read, write and execute permissions
`NET_RAW`    | craft any network packet
`SETUID`     | become any user
`SYS_ADMIN`  | mount, and a lot more: not in the default list

A process that runs as another user holds none of them, a process that runs as root holds them, until the container drops them.

## Root and its capabilities

1. A container runs as root by default:

   <!-- verify: requires=network timeout=120 expect="uid=0(root)" -->

   ```bash exec target=docker
   docker run --rm "${ALPINE_IMAGE}" id
   ```

2. Its capabilities are in the file `/proc/self/status`, as a mask:

   <!-- verify: requires=network timeout=60 expect="a80425fb" -->

   ```bash exec target=docker
   docker run --rm "${ALPINE_IMAGE}" grep CapEff /proc/self/status
   ```

3. `capsh` turns the mask into names.
   These are the fourteen of the documentation of Docker, the ones of a container started with no option:

   <!-- verify: expect="cap_sys_chroot" -->

   ```bash exec target=docker
   capsh --decode=00000000a80425fb
   ```

## A user

1. `--user` starts the process as another user, with no capability left:

   <!-- verify: expect="uid=1000" -->

   ```bash exec target=docker
   docker run --rm --user 1000:1000 "${ALPINE_IMAGE}" sh -c 'id; grep CapEff /proc/self/status'
   ```

   In an image, the same is the `USER` instruction, as in the course Container base images.
   An image with no user the application can run as is a reason to change the image, and not to go back to root.

## Drop what root does not need

1. A root that holds no capability can no longer change an owner:

   <!-- verify: expect="Operation not permitted" -->

   ```bash exec target=docker
   { docker run --rm --cap-drop ALL "${ALPINE_IMAGE}" chown 1:1 /etc/hostname || true; }
   ```

2. The usual form is to drop everything and to add back what the application proves it needs, for example `--cap-add NET_BIND_SERVICE` to listen on a port below 1024.
   A list that grows over time is the sign of an application to review, not of a limit of the method.

## A disk that is not writable

1. An attacker who runs code in the container writes tools to its disk.
   A read-only root filesystem refuses it, and `--tmpfs` gives a temporary writable directory where the application needs one:

   <!-- verify: expect="Read-only file system" -->

   ```bash exec target=docker
   { docker run --rm --read-only "${ALPINE_IMAGE}" sh -c 'echo x > /etc/x' || true; }
   ```

2. A writable `/tmp` of memory, and nothing else:

   <!-- verify: expect="2 bytes in tmp" -->

   ```bash exec target=docker
   docker run --rm --read-only --tmpfs /tmp "${ALPINE_IMAGE}" sh -c 'echo x > /tmp/x && echo "$(wc -c < /tmp/x) bytes in tmp"'
   ```

## No new privileges

A program with the `setuid` bit, `sudo` or `su`, runs with the rights of its owner, which is the usual way from a user to root inside a container.

1. An image with a user that can use `sudo`, as many images made for developers:

   ```bash exec target=docker
   mkdir -p ~/lab/sudo && cd ~/lab/sudo && \
   tee Dockerfile <<EOT
   FROM ${ALPINE_IMAGE}
   RUN apk add --no-cache sudo && adduser -D app && \\
       echo 'app ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/app
   USER app
   EOT
   docker build -q -t sudo-app . > /dev/null
   ```

2. The user becomes root:

   <!-- verify: expect="uid=0(root)" -->

   ```bash exec target=docker
   docker run --rm sudo-app sudo id
   ```

3. `no-new-privileges` stops the kernel from granting rights on `exec`, so `sudo` cannot work:

   <!-- verify: expect="prevents sudo from running as root" -->

   ```bash exec target=docker
   { docker run --rm --security-opt no-new-privileges sudo-app sudo id || true; }
   ```

## The limits

- **The application decides**: a program that needs a capability, a writable path or a root user is not helped by an option, and the work is on the application or on the image.

- **Root in the container is still root of the files it is given**: a bind mount opened to a container that runs as root is opened to root, which the step Host shows.

- **Portable**: the options are standard, and Podman, containerd and Kubernetes (`securityContext`) have the same ones, with no tie to a vendor.
