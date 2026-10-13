# Setup

Docker Engine, k3d, kubectl, a Git server and the Argo CD command line are installed in the virtual machine that has just been created for this lab.
The clusters are k3d clusters, and the Git server is Gitea, which holds the repository Argo CD follows.

> [!NOTE]
> These steps are shown on purpose, so nothing is done by "magic" and this lab can be reproduced in any environment.

## On a workstation

Any cluster and any Git server do: kind, minikube or a managed service, GitHub, GitLab or Forgejo.
This lab keeps everything in one machine, with no account.

System         | Install
---------------|---------------------------------------------------------------------------------------------------------------------------------------
Windows, macOS | [Docker Desktop](https://docs.docker.com/desktop/), then k3d and `argocd` with Homebrew, Chocolatey or Scoop
Linux          | Docker Engine, as in this step, then the binaries of the releases
Any            | [k3d installation](https://k3d.io/stable/#installation), [Argo CD CLI installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

<!-- include: ../../shared/setup-docker.md -->

<!-- include: ../../shared/setup-k3d.md -->

<!-- include: ../../shared/setup-kubectl.md -->

<!-- include: ../../shared/setup-gitea.md -->

<!-- include: ../../shared/setup-argocd-cli.md -->

## Gitea for the clusters

Gitea listens on the loopback of the machine, which is where the commands of this lab reach it.
Argo CD runs in a Pod, and reaches the machine by `host.k3d.internal`, a name k3d adds to the DNS of its clusters for the gateway of the Docker network.
The loopback is not that address, so the server listens on every address of the machine, which is safe here because the machine is disposable and nothing outside reaches it.

1. Listen on every address, and stop the server:

   <!-- verify: expect="stopped, listening on 0.0.0.0" -->

   ```bash exec target=docker
   sed -i 's/^HTTP_ADDR = 127.0.0.1/HTTP_ADDR = 0.0.0.0/' /etc/gitea/app.ini && \
   pkill -f "^gitea web" ; sleep 2 ; \
   echo "stopped, listening on $(grep '^HTTP_ADDR' /etc/gitea/app.ini | cut -d ' ' -f 3)"
   ```

2. Start it again, as the user `git`:

   ```bash exec target=docker
   cd /var/lib/gitea
   nohup runuser -u git -- env GITEA_WORK_DIR=/var/lib/gitea gitea web --config /etc/gitea/app.ini > /var/log/gitea.log 2>&1 &
   ```

3. Wait until it answers:

   <!-- verify: timeout=90 expect="pass" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do wget -qO- "${GITEA_BASE_URL}/api/healthz" > /dev/null 2>&1 && break; sleep 1; done; \
   wget -qO- "${GITEA_BASE_URL}/api/healthz" | grep -m 1 '"status"'
   ```
