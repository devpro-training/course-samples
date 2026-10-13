# A cluster as a file

A command with many flags is hard to share and to repeat.
k3d reads the same options from a YAML file, which a repository keeps beside the code, so every developer creates the same cluster.

## The config file

A file has an `apiVersion` and a `kind`, which is `Simple`, then the options, one key per flag: `servers` is `--servers`, `agents` is `--agents`, `ports` is `--port`.
The `nodeFilters` of a flag become a list in the file.
The format is `k3d.io/v1alpha5`, and the documentation says the configuration is still in alpha, so its fields may change between versions.

1. Write a file for a cluster of one server and one agent, with the port of the previous steps.
   It also gives an option to the servers of k3s, as `--k3s-arg` does, to disable the metrics server, a component that a development cluster often does not need:

   ```bash exec target=docker
   mkdir -p ~/lab/config && cd ~/lab/config && \
   tee dev.yaml <<EOT
   apiVersion: k3d.io/v1alpha5
   kind: Simple
   metadata:
     name: dev
   servers: 1
   agents: 1
   image: ${NODE_IMAGE}
   ports:
     - port: 8080:80
       nodeFilters:
         - loadbalancer
   options:
     k3s:
       extraArgs:
         - arg: --disable=metrics-server
           nodeFilters:
             - server:*
   EOT
   ```

2. Create the cluster from the file:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   cd ~/lab/config && k3d cluster create --config dev.yaml
   ```

3. Two nodes, as the file says, and no metrics server:

   <!-- verify: timeout=120 expect="agent-0" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes --no-headers 2> /dev/null | grep -c " Ready" | grep -q 2 && break; sleep 2; done; \
   kubectl get nodes
   ```

   <!-- verify: timeout=120 expect="metrics-server deployments: 0" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get deployments --namespace kube-system --no-headers 2> /dev/null | grep -q local-path && break; sleep 2; done; \
   kubectl get deployments --namespace kube-system && \
   echo "metrics-server deployments: $(kubectl get deployments --namespace kube-system --no-headers | grep -c metrics-server)"
   ```

## Change a running cluster

A node is a container, so one is added or removed without touching the others.

1. Add an agent to the cluster.
   The name of a node created this way does not repeat the name of the cluster:

   <!-- verify: expect="Successfully created 1 node" -->

   ```bash exec target=docker
   k3d node create extra --cluster dev --role agent
   ```

   <!-- verify: expect="k3d-extra-0" -->

   ```bash exec target=docker
   k3d node list && kubectl get nodes
   ```

2. Delete the cluster.
   The file stays, and the same command creates it again:

   <!-- verify: expect="Successfully deleted cluster" -->

   ```bash exec target=docker
   k3d cluster delete dev
   ```

## Several clusters

Each cluster has its own containers, network and context, so a developer keeps one per project, and one for a test.
The ports of the load balancers must differ.

1. Create two clusters, and list them:

   <!-- verify: requires=network timeout=300 expect="LOADBALANCER" -->

   ```bash exec target=docker
   k3d cluster create one --image "${NODE_IMAGE}" --port "8081:80@loadbalancer" > /dev/null 2>&1 && \
   k3d cluster create two --image "${NODE_IMAGE}" --port "8082:80@loadbalancer" > /dev/null 2>&1 && \
   k3d cluster list
   ```

2. The kubeconfig has a context for each one, and the last one created is current.
   `kubectl config use-context` switches:

   <!-- verify: expect="k3d-two" -->

   ```bash exec target=docker
   kubectl config get-contexts
   ```

   <!-- verify: expect="k3d-one-server-0" -->

   ```bash exec target=docker
   kubectl config use-context k3d-one && kubectl get nodes
   ```

3. Delete them all:

   <!-- verify: expect="Successfully deleted cluster two" -->

   ```bash exec target=docker
   k3d cluster delete --all
   ```

## More servers

`--servers 3` creates three servers.
The documentation says that without an external datastore, the first server starts the cluster with `--cluster-init`, which selects embedded etcd, and the others join it.
The load balancer then spreads the API port over the three.
Three servers and several agents are three containers each, on one machine, so this is a test of how the cluster behaves, and not a high availability setup: they share the kernel, the disk and the power of the machine.

References: [config file](https://k3d.io/stable/usage/configfile/), [defaults](https://k3d.io/stable/design/defaults/).
