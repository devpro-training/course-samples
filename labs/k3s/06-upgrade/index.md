# Upgrade

A k3s upgrade replaces one file and restarts it.
The Pods are processes of the node, which keep running while the server is stopped, so a short restart does not stop what is deployed.

## Before

1. Deploy something that must survive the upgrade:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=kube
   kubectl create deployment web --image="${NGINX_IMAGE}" --replicas=2 && \
   kubectl rollout status deployment/web --timeout=200s
   ```

2. The version of the node:

   <!-- verify: expect="v1.35." -->

   ```bash exec target=kube
   kubectl get nodes
   ```

## Back up and replace

A minor version is not skipped: the documentation says to follow the Kubernetes version skew policy, which allows one minor version at a time.
With several nodes, the servers are upgraded first, one at a time, then the agents.

1. Stop the server.
   The containers are still there:

   <!-- verify: expect="nginx: master process" -->

   ```bash exec target=kube
   pkill -f "^k3s server"; sleep 5; \
   ps -eo args | grep "[n]ginx: master process"
   ```

2. Back up the datastore and the token.
   A copy of the folder is the backup of SQLite, and it is unusable without the token that encrypted its secrets:

   <!-- verify: expect="state.db" -->

   ```bash exec target=kube
   mkdir -p ~/lab/backup && \
   cp -a /var/lib/rancher/k3s/server/db /var/lib/rancher/k3s/server/token ~/lab/backup/ && \
   ls -lh ~/lab/backup/db
   ```

3. Download the new binary, compare it with its checksums, and replace the old one:

   <!-- verify: requires=network timeout=240 expect="k3s version v1.36" -->

   ```bash exec target=kube
   mkdir -p ~/lab/upgrade && cd ~/lab/upgrade && \
   wget -q "${K3S_RELEASE_URL}/${K3S_UPGRADE_VERSION/+/%2B}/k3s" "${K3S_RELEASE_URL}/${K3S_UPGRADE_VERSION/+/%2B}/sha256sum-amd64.txt" && \
   grep -E " k3s$" sha256sum-amd64.txt | sha256sum --check && \
   install -m 0755 k3s /usr/local/bin/k3s && \
   k3s --version
   ```

4. Start the server again.
   It reads the files and the datastore of the previous version:

   ```bash exec target=kube
   nohup k3s server > /var/log/k3s.log 2>&1 &
   ```

## After

1. Wait until the node reports the new version:

   <!-- verify: timeout=240 expect="v1.36." -->

   ```bash exec target=kube
   for i in $(seq 1 100); do kubectl get nodes 2> /dev/null | grep -q "v1.36" && break; sleep 3; done; \
   kubectl get nodes
   ```

2. The deployment was not touched:

   <!-- verify: timeout=120 expect="successfully rolled out" -->

   ```bash exec target=kube
   kubectl rollout status deployment/web --timeout=100s && kubectl get pods
   ```

On a node installed with the script, the same upgrade is the script run again with the version, which downloads the binary, restarts the service, and keeps the options in `config.yaml`:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=<version> sh -
```

For many nodes, the [system-upgrade-controller](https://docs.k3s.io/upgrades/automated) does the same from a `Plan` object, node by node.
The page on [manual upgrades](https://docs.k3s.io/upgrades/manual) also says how to cordon and drain a node first, which the script does not do.
