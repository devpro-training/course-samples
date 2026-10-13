# A local registry

The nodes run their own containerd, inside their containers, and do not see the images of the Docker engine that runs them.
An image built on the machine reaches the cluster through a registry, or by being copied into the nodes.

## A registry and a cluster that uses it

1. Create a registry.
   It is a container like the nodes, named with the prefix `k3d-`, and its port is published on the machine:

   <!-- verify: requires=network timeout=240 expect="k3d-registry.localhost:5000" -->

   ```bash exec target=docker
   k3d registry create registry.localhost --port 5000
   ```

2. Create a cluster that uses it.
   k3d writes the registry into the configuration of containerd in every node, and its name into the DNS of the cluster:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create dev --image "${NODE_IMAGE}" --registry-use k3d-registry.localhost:5000
   ```

3. The configuration of the node, and the registry as the list shows it:

   <!-- verify: expect="endpoint" -->

   ```bash exec target=docker
   docker exec k3d-dev-server-0 cat /etc/rancher/k3s/registries.yaml && k3d registry list
   ```

## Build, push and run

1. Build an image on the machine, from a Dockerfile of two lines:

   <!-- verify: requires=network timeout=180 expect="built: 1" -->

   ```bash exec target=docker
   mkdir -p ~/lab/registry && cd ~/lab/registry && \
   tee Dockerfile <<EOT
   FROM ${BUSYBOX_IMAGE}
   CMD ["echo", "built on the machine"]
   EOT
   docker build --quiet --tag app:dev . > /dev/null && \
   echo "built: $(docker image ls --quiet app:dev | wc -l)"
   ```

2. Tag it with the address of the registry on the machine, and push it.
   The machine reaches the registry on `127.0.0.1`, or `localhost`, and Docker accepts a registry there without TLS.
   The name `k3d-registry.localhost` is the one the nodes know, so a manifest uses it:

   <!-- verify: expect="digest: sha256" -->

   ```bash exec target=docker
   docker tag app:dev 127.0.0.1:5000/app:dev && docker push 127.0.0.1:5000/app:dev
   ```

   <!-- verify: expect="repositories" -->

   ```bash exec target=docker
   wget -qO- http://127.0.0.1:5000/v2/_catalog; echo
   ```

3. Run a Pod from the image, with the name of the nodes:

   <!-- verify: timeout=180 expect="built on the machine" -->

   ```bash exec target=docker
   kubectl run from-registry --image k3d-registry.localhost:5000/app:dev --restart Never && \
   kubectl wait --for jsonpath='{.status.phase}'=Succeeded pod/from-registry --timeout 150s && \
   kubectl logs from-registry
   ```

   Pushing the same name again replaces the image, and a new Pod runs the new one: the loop of a developer is build, push, and delete the Pod or restart the Deployment.

## Without a registry: import

`k3d image import` copies an image of the Docker engine into the containerd of every node.

1. Build a second version of the image, import it, and run a Pod that must not pull it.
   `imagePullPolicy: Never` makes the kubelet use only what is in the node:

   <!-- verify: timeout=180 expect="Completed" -->

   ```bash exec target=docker
   cd ~/lab/registry && sed -i "s/built on the machine/built for the import/" Dockerfile && \
   docker build --quiet --tag app:import . > /dev/null && \
   k3d image import app:import --cluster dev && \
   kubectl run from-import --image app:import --image-pull-policy Never --restart Never && \
   kubectl wait --for jsonpath='{.status.phase}'=Succeeded pod/from-import --timeout 150s && \
   kubectl logs from-import && kubectl get pod from-import
   ```

   The image has new content.
   When the node already holds the same content under another name, because a Pod pulled it from the registry, the kubelet did not find it under the new name with a policy of `Never`, and the Pod stayed in `ErrImageNeverPull` in this lab.

2. An image that Docker pulled, and did not build, can fail.
   With Docker 29, which stores images with containerd, the import of a pulled image that has several platforms ends with a `content digest ... not found` error from the node.
   k3d prints the error, then reports a success anyway:

   <!-- verify: requires=network timeout=180 expect="content digest" -->

   ```bash exec target=docker
   docker pull --quiet "${BUSYBOX_IMAGE}" > /dev/null && \
   k3d image import "${BUSYBOX_IMAGE}" --cluster dev 2>&1 | grep -E "ERRO|not found|Successfully imported image"
   ```

   This was observed with k3d v5.9.0 and Docker 29.8.2, and the registry route does not have the problem.

Way            | Needs                                                   | Good for
---------------|---------------------------------------------------------|--------------------------------------------------------
Registry       | A container, and a push per change                      | The loop build, push, run, with the names of a pipeline
`image import` | Nothing, and a pull policy of `Never` or `IfNotPresent` | A quick try of an image built here, on one cluster

## Clean up

1. Delete the cluster and the registry.
   The registry is a container of its own, so deleting the cluster leaves it:

   <!-- verify: expect="containers left: 0" -->

   ```bash exec target=docker
   k3d cluster delete dev > /dev/null 2>&1; \
   k3d registry delete k3d-registry.localhost && \
   echo "containers left: $(docker ps --all --quiet | wc -l)"
   ```
