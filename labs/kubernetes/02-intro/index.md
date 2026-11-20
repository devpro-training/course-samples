# Kubernetes

One API to run containers on any infrastructure.

---

## What Kubernetes is

- **An open source system** to deploy, scale and manage containerized applications across many machines.

- **Declarative**: a file says what must run, and the cluster works until what runs matches it, and keeps it that way.

- **A name from Greek**, meaning helmsman or pilot, and **K8s** for short: eight letters between the K and the s.

- **Written in Go**, which the lab shows: `kubectl version -o json` prints the version of Go that built it.

- It is the base of the rest of this series: the tools that follow (ingress controllers, GitOps, Argo CD, Flux, Rancher) all speak its API.

- Reference: [Kubernetes overview](https://kubernetes.io/docs/concepts/overview/).

---

## History: from Borg to the CNCF

![Borg inside Google, Kubernetes open source in 2014, version 1.0 given to the CNCF on 21 July 2015, first graduated CNCF project on 6 March 2018](../assets/kubernetes-history-dark.svg#gh-dark-mode-only)
![Borg inside Google, Kubernetes open source in 2014, version 1.0 given to the CNCF on 21 July 2015, first graduated CNCF project on 6 March 2018](../assets/kubernetes-history.svg#gh-light-mode-only)

---

## Google and Borg

- Google ran containers in production for more than ten years before Kubernetes, on an internal cluster manager named **Borg**, written in C++.

- Borg was described in public for the first time in a paper of EuroSys 2015, [Large-scale cluster management at Google with Borg](https://research.google/pubs/large-scale-cluster-management-at-google-with-borg/).

- Kubernetes was built by many of the same engineers, who kept the best ideas of Borg and fixed what its users had complained about.

- **A Pod** groups the containers that run together, and is the unit of scheduling.

- **A Service** gives a name to a changing set of Pods, and balances the connections.

- **Labels** select the Pods an operation applies to, with no fixed hierarchy.

- **An IP address per Pod**, so an application keeps its own ports.

- Reference: [Borg: the predecessor to Kubernetes](https://kubernetes.io/blog/2015/04/borg-predecessor-to-kubernetes/), 23 April 2015.

---

## Open source, then a neutral home

- Google open sourced Kubernetes in **2014**, in Go, and the documentation counts over 15 years of Google's experience in it.

- **Kubernetes 1.0** came on **21 July 2015**, with the donation of the project to the new **Cloud Native Computing Foundation** (CNCF), run by the Linux Foundation: no single company owns it.

- On **6 March 2018** it became the first project to **graduate** in the CNCF, after proof of broad adoption and a formal governance.

- Today the project maintains the three most recent minor versions, 1.35, 1.36 and 1.37 at the time of writing, and this lab runs 1.36.

- References:
  [CNCF, 21 July 2015](https://www.cncf.io/news/2015/07/21/techcrunch-as-kubernetes-hits-1-0-google-donates-technology-to-newly-formed-cloud-native-computing-foundation), [CNCF,
  6 March 2018](https://www.cncf.io/announcements/2018/03/06/kubernetes-first-cncf-project-graduate/), [Releases](https://kubernetes.io/releases/).

---

## From servers to containers

Era         | How an application runs                              | What was missing
------------|------------------------------------------------------|-------------------------------------------
Physical    | One or more applications on a physical server        | No resource boundary between applications
Virtualized | Virtual machines on a physical server                | A whole system per application
Containers  | Processes isolated by the kernel, sharing the system | Someone to place, restart and connect them

The three eras are the ones of the [Kubernetes documentation](https://kubernetes.io/docs/concepts/overview/).

---

## Why a container needs an orchestrator

One container on one machine is `docker run`.
A hundred containers on twenty machines is a different problem, and every question below has to be answered by something.

Question                                         | In Kubernetes
-------------------------------------------------|---------------------------------------------
Which machine has room for it?                   | The scheduler places each Pod
What if it crashes, or the machine dies?         | The Pod is replaced, on a healthy node
How do others find it, when its address changes? | A Service and a DNS name
How do ten copies share the traffic?             | A Service balances them
How is version 2 rolled out, and undone?         | A Deployment replaces the Pods step by step
Where do the settings and the secrets go?        | ConfigMaps and Secrets, outside the image
How does it grow when the load grows?            | The number of replicas, by hand or automatic

---

## Team velocity

- **The infrastructure is abstracted.**
  A team asks for what the application needs: an image, a number of replicas, memory and CPU.
  It does not ask for a server, and the cluster decides where each Pod runs.

- **One standard.**
  The same objects and the same API run on a laptop, on k3s, on a managed service of any cloud, and the tools of the ecosystem work with all of them.
  What a team learns, and what it writes, is reusable.

- **Scaling is a number.**
  Going from 2 to 20 replicas is a field of a file, which is reviewed, versioned and applied like code.

- **A split of concerns.**
  A platform team runs the cluster, product teams ship to it through the API, and each moves at its own pace.

---

## What Kubernetes brought

- **Self-healing**: containers that fail are restarted or replaced, and a Pod receives traffic only when it is ready.

- **Service discovery and load balancing**, **automatic bin packing** of the Pods on the nodes, and **horizontal scaling**.

- **Automated rollouts and rollbacks**, **secret and configuration management**, **storage orchestration**, **batch execution**.

- **Extensibility**: new kinds of objects (custom resources) and controllers that manage them, which is how databases, certificates or GitOps are added to the cluster.

- **A reconciliation loop**: every controller compares the desired state with the actual state, and acts on the difference, forever.

---

## The CNCF and cloud native

- The CNCF is a part of the Linux Foundation, and hosts open source, vendor-neutral projects.

- A project is a **sandbox** (experimental), **incubating** (used in production by a few) or **graduated** (stable, widely adopted).

- Its definition of **cloud native**: techniques to build and run workloads in public, private and hybrid clouds, made of loosely coupled systems that are secure, resilient, manageable, sustainable and observable.

- The technologies it lists: containers, service meshes, microservices, immutable infrastructure, serverless and declarative APIs.

- The **Certified Kubernetes** program checks that a distribution, a hosted platform or an installer behaves like Kubernetes, with a public test suite.

- References:
  [CNCF definition](https://github.com/cncf/toc/blob/main/DEFINITION.md), [Who we are](https://www.cncf.io/about/who-we-are/), [100 certified vendors,
  2019](https://www.cncf.io/announcements/2019/11/19/cloud-native-computing-foundation-reaches-over-100-certified-kubernetes-vendors/).

---

## Cloud native patterns

Pattern                  | The idea                                                  | In Kubernetes
-------------------------|-----------------------------------------------------------|---------------------------------------------------------------------------------------------
Declarative              | Describe the result, not the steps                        | A manifest, `kubectl apply`
Immutable infrastructure | Replace a running thing, never patch it                   | A rolling update of Pods
Health probes            | The application says whether it is alive and ready        | Liveness and readiness probes
Service discovery        | A stable name in front of a changing set                  | A Service and its DNS name
Configuration outside    | The same image in every environment                       | ConfigMap and Secret
Sidecar                  | A helper container that shares the Pod of the application | [Sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
Operator                 | The knowledge of an operator written as a controller      | [Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

The lab shows the first five.

---

## What a cluster is

![A cluster has a control plane, made of the API server, a datastore, the scheduler and the controller manager,
and worker nodes that run the Pods through the kubelet and a container runtime](../assets/kubernetes-cluster-dark.svg#gh-dark-mode-only)
![A cluster has a control plane, made of the API server, a datastore, the scheduler and the controller manager,
and worker nodes that run the Pods through the kubelet and a container runtime](../assets/kubernetes-cluster.svg#gh-light-mode-only)

---

## The components

A cluster is a **control plane** and one or more **worker nodes**.

Part          | Component                 | Does
--------------|---------------------------|----------------------------------------------------
Control plane | `kube-apiserver`          | Exposes the Kubernetes HTTP API: the only way in
Control plane | `etcd`                    | The consistent key value store of all the API data
Control plane | `kube-scheduler`          | Assigns each new Pod to a suitable node
Control plane | `kube-controller-manager` | Runs the controllers that implement the API
Node          | `kubelet`                 | Makes sure the Pods and their containers run
Node          | `kube-proxy`              | Maintains the network rules that implement Services
Node          | Container runtime         | Runs the containers (containerd, for example)

Reference: [Kubernetes components](https://kubernetes.io/docs/concepts/overview/components/).

---

## A distribution

- Upstream Kubernetes is a set of components to assemble: the choice of the container runtime, of the network plugin, of the storage, of the ingress, of the datastore, and the way to install and upgrade it.

- **A distribution** makes those choices, packages the result, and keeps it up to date: it is still Kubernetes, with the same API.

- **An installer** builds a cluster from the upstream components, `kubeadm` for example, and leaves the choices to the operator.

Name    | Kind         | What it chooses
--------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------
k3s     | Distribution | One binary under 100 MB: containerd, Flannel, CoreDNS, Traefik, a local storage provisioner, SQLite by default
RKE2    | Distribution | Security and compliance first: defaults that pass the CIS benchmark, FIPS 140-2, control plane as static Pods, containerd. Combines k3s and RKE1
kubeadm | Installer    | The upstream way to start a cluster, with no choice made for the network or the storage

References: [k3s](https://docs.k3s.io/), [RKE2](https://docs.rke2.io/), [Production environment](https://kubernetes.io/docs/setup/production-environment/).

---

## Distribution or managed service

- **A managed service** (Google GKE, Amazon EKS, Azure AKS) lets the provider run the control plane: its scale, its availability, its patches and its upgrades, and optionally the worker nodes too.

- **Running a distribution** means building that availability: several control plane machines, a load balancer in front of the API, backups of the datastore, certificates, upgrades.

Question                    | Distribution on own machines               | Managed service
----------------------------|--------------------------------------------|----------------------------------------------
Who runs the control plane? | The team                                   | The provider
Where does it run?          | Anywhere: a laptop, a server, an edge site | The cloud of the provider
What does the team keep?    | Everything, the machines included          | The workloads, the configuration and the cost
What does it tie it to?     | The distribution and its upgrade path      | The provider and its integrations

- Both are Kubernetes: a manifest written for one is applied to the other, which is the point of the standard.

- Both stay a choice of the team: neither removes the need to run workloads well.

---

## The datastore, and k3s

- Kubernetes keeps every object of the API in a datastore, **etcd**, and only the API server talks to it.

- **k3s** keeps the same API and changes the datastore: **SQLite** by default, in one file, which suits a single server and needs no other process.

- **Kine** is the shim between them: "an etcdshim that provides an etcd-compatible API on top of various backends", the subset of the etcd API that the API server needs.

- **Embedded etcd** is selected when a cluster has several servers, and SQLite cannot be used with several servers.
  An external MySQL, MariaDB, PostgreSQL or etcd is also supported.

- The lab reads the SQLite file of the server, and finds the objects of the cluster in it.

- References: [k3s datastore](https://docs.k3s.io/datastore), [Kine](https://github.com/k3s-io/kine).

---

## In this lab

Step        | What it shows
------------|-------------------------------------------------------------------------
Setup       | The k3s binary, checked against its checksum, and a running server
Cluster     | The node, the system Pods, the API, and the datastore file
Pods        | A manifest, `kubectl apply`, logs, `exec`, and a Pod that stays gone
Deployments | Replicas, self-healing, scaling, a rolling update and a rollback
Services    | Labels, a name that balances, DNS inside the cluster, a port on the node
Config      | A ConfigMap and a Secret, and where each is stored

> A virtual machine of its own, and no account: the binary comes from GitHub, and the images from Docker Hub, which allow anonymous downloads.
