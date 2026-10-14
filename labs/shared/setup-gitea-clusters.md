## Gitea for the clusters

Gitea listens on the loopback of the machine, which is where the commands of this lab reach it.
The GitOps controller runs in a Pod, and reaches the machine by `host.k3d.internal`, a name k3d adds to the DNS of its clusters for the gateway of the Docker network.
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
