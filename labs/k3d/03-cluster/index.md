# The cluster

A k3d cluster is a few Docker containers: the nodes of k3s, and a small load balancer in front of them.
Creating one is a single command, and so is deleting it.

## Create a cluster

1. Create a cluster named `dev`.
   The image is the one of the nodes, pinned in `lab.yaml`: k3d has its own default k3s version, and the cluster created here follows the stable channel of k3s instead.
   The first creation pulls the images, the next ones start from the cache:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create dev --image "${NODE_IMAGE}"
   ```

   The log tells what k3d did: it created a Docker network and a volume, started a helper node (`k3d-dev-tools`) to look at the Docker environment, started the server, started the load balancer,
   and added DNS records to CoreDNS.

2. List the clusters:

   <!-- verify: expect="1/1" -->

   ```bash exec target=docker
   k3d cluster list
   ```

## What is running

1. The nodes are containers.
   The helper node is gone, and the load balancer is `k3d-proxy`, an nginx that forwards TCP ports to the servers:

   <!-- verify: expect="k3d-proxy" -->

   ```bash exec target=docker
   docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
   ```

   The cluster has its own Docker network, and the containers reach each other by name on it:

   <!-- verify: expect="k3d-dev" -->

   ```bash exec target=docker
   docker network ls --filter name=k3d --format "{{.Name}}"
   ```

2. `kubectl` works at once: k3d added a context to the kubeconfig and switched to it.
   Kubernetes sees one node, which is the `k3d-dev-server-0` container, with an address of the Docker network:

   <!-- verify: expect="admin@k3d-dev" -->

   ```bash exec target=docker
   kubectl config get-contexts
   ```

   <!-- verify: expect="control-plane" -->

   ```bash exec target=docker
   kubectl get nodes --output wide
   ```

3. The API server is reached through the load balancer, on a port k3d publishes on the machine.
   The port is random unless `--api-port` is given:

   <!-- verify: expect="https://0.0.0.0:" -->

   ```bash exec target=docker
   kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}{"\n"}' && \
   docker port k3d-dev-serverlb 6443
   ```

4. The node is a k3s server, with the components the k3s course lists: CoreDNS, Traefik and the local path provisioner.
   Wait until the Pods run:

   <!-- verify: timeout=240 expect="svclb-traefik" -->

   ```bash exec target=docker
   for i in $(seq 1 120); do kubectl get pods --namespace kube-system --no-headers 2> /dev/null | grep -qE "^traefik-.* Running" && break; sleep 2; done; \
   kubectl get pods --namespace kube-system
   ```

## What it costs

A node is a container, so the machine pays for what k3s runs, and the cluster has the privileges Kubernetes asks of a node.

1. The memory of the containers, once the cluster is idle.
   A k3s server uses several hundred MiB, the load balancer a few tens:

   <!-- verify: expect="MEM USAGE" -->

   ```bash exec target=docker
   docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
   ```

2. The node is a privileged container.
   What escapes from a Pod into the node has the rights of that container on the machine, which is a reason to keep a k3d cluster for development:

   <!-- verify: expect="privileged=true" -->

   ```bash exec target=docker
   docker inspect k3d-dev-server-0 --format 'privileged={{.HostConfig.Privileged}}'
   ```

## Stop, start and delete

A stopped cluster costs no CPU and keeps its state, which is the difference with deleting it.

1. Stop the cluster.
   No container of it runs any more:

   <!-- verify: expect="Stopped cluster" -->

   ```bash exec target=docker
   k3d cluster stop dev && docker ps --format "{{.Names}}" | wc -l
   ```

2. Start it again, and wait until the node answers:

   <!-- verify: timeout=240 expect="k3d-dev-server-0" -->

   ```bash exec target=docker
   k3d cluster start dev && \
   for i in $(seq 1 120); do kubectl get nodes 2> /dev/null | grep -q " Ready.*control-plane" && break; sleep 2; done; \
   kubectl get nodes
   ```

3. Delete it.
   The containers, the network, the volumes and the entry of the kubeconfig go with it:

   <!-- verify: expect="Successfully deleted cluster" -->

   ```bash exec target=docker
   k3d cluster delete dev && docker ps --all --format "{{.Names}}" | wc -l
   ```

> [!NOTE]
> The next steps create a cluster with the options they need, and delete it at the end.
