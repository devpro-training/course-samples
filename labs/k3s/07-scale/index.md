# Scale

A k3s cluster grows by adding nodes.
An agent runs `kubelet`, the container runtime and the network, with no control plane and no datastore, and joins a server with its address and a token.

## The token

1. The server read the token from the variable `K3S_TOKEN` when it started, and keeps it in a file.
   The file holds the secure format, which starts with `K10` and carries the hash of the certificate authority of the cluster, so an agent knows which server it joins:

   <!-- verify: expect="K10" -->

   ```bash exec target=kube
   cut -c1-3 /var/lib/rancher/k3s/server/token
   ```

   A real cluster generates its token, and [k3s token create](https://docs.k3s.io/cli/token) makes temporary ones.

## The agent

The second terminal is the machine `agent`, which is reached from `kube` by its name.

1. Run the install script on the agent.
   `K3S_URL` is the address of the server, which makes it install an agent, and `K3S_TOKEN` is already in the environment.
   The script downloads the binary of the version asked, compares it with the checksum, and writes the service file and the removal script.
   As on the server, no service is enabled or started:

   <!-- verify: requires=network timeout=240 expect="Verifying binary download" -->

   ```bash exec target=agent
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${K3S_INSTALL_URL}" -O install.sh && \
   K3S_URL="${CLUSTER_URL}" INSTALL_K3S_VERSION="${K3S_UPGRADE_VERSION}" INSTALL_K3S_SKIP_ENABLE=true INSTALL_K3S_SKIP_START=true sh install.sh
   ```

2. Start the agent, as the service would: it reads the address of the server and the token from its environment.

   ```bash exec target=agent
   K3S_URL="${CLUSTER_URL}" nohup k3s agent > /var/log/k3s-agent.log 2>&1 &
   ```

3. The server lists the new node.
   An agent has no role:

   <!-- verify: timeout=240 expect="<none>" -->

   ```bash exec target=kube
   for i in $(seq 1 100); do kubectl get nodes 2> /dev/null | grep -q "^agent .* Ready" && break; sleep 3; done; \
   kubectl get nodes -o wide
   ```

4. The agent generated a password, which it keeps in `/etc/rancher/node/password`, and the server keeps its hash in a Secret:

   <!-- verify: expect="node-password.k3s" -->

   ```bash exec target=kube
   kubectl get secrets --namespace kube-system | grep node-password
   ```

## Use the second node

1. Scale the deployment, and see where the Pods are placed:

   <!-- verify: timeout=240 expect="NODE" -->

   ```bash exec target=kube
   kubectl scale deployment web --replicas=6 && \
   kubectl rollout status deployment/web --timeout=200s && \
   kubectl get pods --selector app=web --output wide
   ```

2. On the agent, the containers are the ones of the Pods placed there, and there is no server folder:

   <!-- verify: timeout=60 expect="nginx" -->

   ```bash exec target=agent
   k3s crictl ps
   ```

   <!-- verify: expect="No such file" -->

   ```bash exec target=agent
   ls /var/lib/rancher/k3s/server 2>&1 | head -n 1
   ```

## More servers

One server is a single point of failure.
A cluster of several servers needs embedded etcd (`--cluster-init` on the first server, then `--server` on the others), an odd number of servers, three or more as the documentation recommends,
and optionally a fixed address for the agents to register with (`--tls-san`).
SQLite cannot be shared between servers, and a cluster that runs on it is converted by restarting its server with `--cluster-init`.
The [high availability](https://docs.k3s.io/datastore/ha-embedded) pages describe both modes.
