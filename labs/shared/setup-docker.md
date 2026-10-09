## The machine

Containers share the kernel of the machine they run on and need its cgroups, so Docker needs a real Linux kernel and administrator rights.
The lab image gives neither, and this lab declares a virtual machine of its own instead (`runtime: vm` in `lab.yaml`): a Debian 12 userland, with its own kernel, and a shell that is `root` already.
The terminal of this lab is that machine.

1. Check the system and the user:

   <!-- verify: expect="Debian GNU/Linux 12" -->

   ```bash exec target=docker
   . /etc/os-release && echo "${PRETTY_NAME}" && uname -r && id -un
   ```

## Versions

Every version and URL of this lab is a variable declared under `env:` in `lab.yaml`, so every shell of this machine has them.
They are the ones to change to follow a newer release, or another mirror.

1. Check that they arrived:

   <!-- verify: expect="Docker 5:29" -->

   ```bash exec target=docker
   echo "Docker ${DOCKER_VERSION}"
   ```

## Docker's apt repository

The packages of Docker Engine are signed with a key that Docker publishes, so the key is downloaded first and its fingerprint is compared with the one in the documentation.

1. Install `iptables`, which the daemon uses to publish ports.
   `DEBIAN_FRONTEND=noninteractive` stops `apt-get` from asking questions that nobody would answer:

   <!-- verify: requires=network timeout=180 -->

   ```bash exec target=docker
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get update -qq && \
   apt-get install -y -qq iptables > /dev/null 2>&1
   ```

2. Download the key, and compare its fingerprint with the one of the documentation.
   The command fails when they differ, and prints the fingerprint when they match:

   <!-- verify: requires=network timeout=60 expect="9DC8 5822 9FC7 DD38" -->

   ```bash exec target=docker
   install -m 0755 -d /etc/apt/keyrings && \
   wget -q "${DOCKER_APT_URL}/gpg" -O /etc/apt/keyrings/docker.asc && \
   chmod a+r /etc/apt/keyrings/docker.asc && \
   gpg --show-keys --with-colons /etc/apt/keyrings/docker.asc 2> /dev/null | grep -q "fpr:::::::::${DOCKER_GPG_FINGERPRINT}:" && \
   gpg --show-keys --fingerprint /etc/apt/keyrings/docker.asc
   ```

3. Declare the repository, for the release and the architecture of this machine:

   <!-- verify: requires=network timeout=120 expect="Suites: bookworm" -->

   ```bash exec target=docker
   tee /etc/apt/sources.list.d/docker.sources <<EOT
   Types: deb
   URIs: ${DOCKER_APT_URL}
   Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
   Components: stable
   Architectures: $(dpkg --print-architecture)
   Signed-By: /etc/apt/keyrings/docker.asc
   EOT
   apt-get update -qq
   ```

## Docker Engine

1. Install the engine, its command line, the container runtime it relies on, and the Buildx and Compose plugins:

   <!-- verify: requires=network timeout=300 expect="Docker version 29." -->

   ```bash exec target=docker
   export DEBIAN_FRONTEND=noninteractive && \
   apt-get install -y -qq docker-ce="${DOCKER_VERSION}" docker-ce-cli="${DOCKER_VERSION}" containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1 ; \
   docker --version
   ```

2. Start the daemon.
   The machine runs no init system, so `dockerd` is started in the background, and the next command waits until it answers:

   ```bash exec target=docker
   nohup dockerd > /var/log/dockerd.log 2>&1 &
   ```

   <!-- verify: expect="Server Version: 29." -->

   ```bash exec target=docker
   for i in $(seq 1 30); do docker info > /dev/null 2>&1 && break; sleep 1; done; \
   docker info | grep -E "Server Version|Storage Driver|Cgroup Version"
   ```

   > [!NOTE]
   > On a machine with systemd, the package starts the daemon by itself, and `systemctl status docker` shows it.

3. Run the image Docker publishes to check an installation.
   The client asks the daemon, which pulls the image from Docker Hub and runs it:

   <!-- verify: requires=network timeout=120 expect="Hello from Docker!" -->

   ```bash exec target=docker
   docker run --rm hello-world
   ```

> [!NOTE]
> The editor of the lab shows the files of the lab container, not of this machine, so the files of this course are written by the commands, which show their content.
