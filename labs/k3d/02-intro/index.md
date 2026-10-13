# k3d

A small, easy Kubernetes cluster on any system that runs Docker.

---

## What k3d is

- **A wrapper around k3s**: the documentation says "a lightweight wrapper to run k3s (Rancher Lab's minimal Kubernetes distribution) in docker".

- **One binary, one command**: `k3d cluster create` starts a cluster, `k3d cluster delete` removes it.

- **Nodes are containers**: a default cluster is one k3s container and one load balancer container, and more nodes are more containers.

- **For local development**: the documentation presents it for creating single and multi-node k3s clusters, "for example for local Kubernetes development".

- **Community driven, MIT**: the documentation says it is not an official Rancher (SUSE) product, and the repository [k3d-io/k3d](https://github.com/k3d-io/k3d) carries an MIT licence.

- **The version of the lab**: v5.9.0, released on 2 June 2026, which needs Docker 20.10.5 or newer.

- **Prerequisites**: the Kubernetes and k3s courses, which explain the objects and the k3s components this course uses without redoing them.

- References: [k3d.io](https://k3d.io/), [releases](https://github.com/k3d-io/k3d/releases).

---

## Why a developer wants it

Need                        | What k3d gives
----------------------------|-------------------------------------------------------------------------------------------
A cluster on a laptop       | Tens of seconds and under a GiB, with no virtual machine of its own to manage
The same on every system    | Docker on Linux, macOS and Windows is the only requirement, and the commands do not change
A clean state for each test | Delete the cluster, create it again, with the same file
Several clusters at once    | One context each, side by side: a project, a test, a version
Multi-node tests            | `--agents 2` is two containers, not two machines
Images built on the machine | A registry in a container, or an import into the nodes
No cloud account            | Everything is local, and the images come from public registries

- k3s is what runs in the nodes: the cluster has the API and the components of the k3s course, Traefik, CoreDNS and local-path included.

- The lab measures an idle server at several hundred MiB, and a cluster at about twenty seconds.

---

## How it works

![The machine reaches a cluster through the ports published by its load balancer container, on a Docker network that holds the server, the agents and a registry](../assets/k3d-cluster-dark.svg#gh-dark-mode-only)
![The machine reaches a cluster through the ports published by its load balancer container, on a Docker network that holds the server, the agents and a registry](../assets/k3d-cluster.svg#gh-light-mode-only)

---

## Install

System       | Install
-------------|------------------------------------------------------------------------------------
Linux, macOS | The install script, `brew install k3d`, or the binary of a release
Windows      | `choco install k3d`, `scoop install k3d`, or the binary
Any          | `arkade get k3d`, `asdf`, the AUR, or `go install` (which gives unreleased changes)

- Docker is the only requirement, and `kubectl` is separate, since k3d creates clusters and does not carry it.

- The lab downloads the binary of the release and compares it with the `checksums.txt` of the release, and pins the version.

- Reference: [installation](https://k3d.io/stable/#installation).

---

## Ports and ingress

- **The only way in is a published port**, and k3d publishes them on the load balancer: `--port "8080:80@loadbalancer"` is the port 8080 of the machine to the port 80 of the servers.

- **Traefik answers there**, so an `Ingress` is enough for HTTP: the same page opens on `localhost:8080` on every system.

- **The API port** is published on the load balancer too, random unless `--api-port` is given, and k3d writes it in the kubeconfig.

- **Ports are chosen at creation**, and `k3d cluster edit --port-add` adds one by replacing the load balancer container.

- **A `LoadBalancer` Service** gets the address of a node container: it answers from a Linux machine, and the Docker documentation says the bridge network is not reachable from the host on Docker Desktop.

- **A port serves one Service** on a node with ServiceLB, and Traefik uses 80 and 443, so another `LoadBalancer` Service takes another port.

- **From a Pod to the machine**: `host.k3d.internal`.

- References: [exposing services](https://k3d.io/stable/usage/exposing_services/), [ServiceLB](https://docs.k3s.io/networking/networking-services),
  [Docker Desktop networking](https://docs.docker.com/desktop/features/networking/networking-how-tos/).

---

## Storage

- **`local-path` is the default**: a volume is a folder of the node, here a folder in a container, on a Docker volume.

- **It is tied to a node**: the volume has a node affinity, and the Pod follows it.

- **It survives** the deletion of a Pod and a stop of the cluster, **and it is lost** with the cluster.

- **A stop drains the server**: k3d's entrypoint runs `kubectl drain --force --disable-eviction` on it, so a Pod with no controller on the server is deleted, and a Deployment creates it again.

- **One node, one writer**: `ReadWriteOnce`, with no replication, as in k3s.

- **To keep data**, `--volume <folder>:/var/lib/rancher/k3s/storage@all` puts the volumes in a folder of the machine, which Docker Desktop must share.

- **For an application that must survive**, a database or an object store outside the cluster.

---

## Registry

- **The nodes have their own containerd**, which does not see the images of the Docker engine.

- **A registry in a container**: `k3d registry create`, then `--registry-use`, and the nodes pull from `k3d-registry.localhost:5000`.

- **The machine pushes to `localhost:5000`**, and a manifest uses the name of the nodes.

- **`k3d image import`** copies an image into the nodes: the lab shows it for an image built there, and an error for a pulled multi-platform image with Docker 29.

- Reference: [registries](https://k3d.io/stable/usage/registries/).

---

## Alongside the others

Tool     | In its own words
---------|--------------------------------------------------------------------------------------------------------------------------------
k3d      | A wrapper to run k3s in Docker, for local development
kind     | "A tool for running local Kubernetes clusters using Docker container nodes", "primarily designed for testing Kubernetes itself"
minikube | "Local Kubernetes, focusing on making it easy to learn and develop for Kubernetes", on Docker or a virtual machine

- All three run a real Kubernetes on a developer machine, and the choice is about the distribution in the nodes and the tools around it.

- k3d stays close to k3s, the distribution of the k3s course, which is why this course follows it.

- References: [kind](https://kind.sigs.k8s.io/), [minikube](https://minikube.sigs.k8s.io/docs/start/).

---

## Limits

Limit                        | What to do
-----------------------------|------------------------------------------------------------------------------
Nodes are privileged         | A cluster for development and tests, not for production or untrusted code
One machine                  | Three servers are three containers: a test of behavior, not high availability
Ports fixed at creation      | `--port-add`, or a config file kept in the repository
Storage lost on delete       | A folder of the machine, or a service outside the cluster
A stop deletes bare Pods     | Deployments, as in any cluster: the servers are drained when they stop
`LoadBalancer` addresses     | Publish a port on the load balancer instead
`image import` and Docker 29 | A registry
Config in alpha              | Pin the k3d version, as the lab does

---

## In this lab

Step                | What it shows
--------------------|---------------------------------------------------------------------------
Setup               | Docker Engine, then k3d and kubectl from checked release binaries
The cluster         | Create, anatomy, cost, stop, start, delete
Ports and ingress   | A published port, an Ingress, `LoadBalancer` Services, `host.k3d.internal`
Storage             | `local-path` in a container, what survives, a folder of the machine
A local registry    | Build, push and run, `image import` and its limit
A cluster as a file | The config file, a node added, several clusters

> One virtual machine and no account: the binaries come from GitHub and Kubernetes, and the images from Docker Hub and GitHub Container Registry.
