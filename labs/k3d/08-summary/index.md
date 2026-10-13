# Summary

---

## Cheat sheet

Task                  | Command
----------------------|-------------------------------------------------------------------------------------------
Create a cluster      | `k3d cluster create <name> --image <image>`, or `--config <file>`
Publish a port        | `--port "8080:80@loadbalancer"`, or `k3d cluster edit <name> --port-add ...`
Add agents or servers | `--agents <n>`, `--servers <n>`, or `k3d node create <name> --cluster <name> --role agent`
Mount a folder        | `--volume "<folder>:<path>@all"`
Create a registry     | `k3d registry create <name> --port 5000`, then `--registry-use k3d-<name>:5000`
Copy an image         | `k3d image import <image> --cluster <name>`
List                  | `k3d cluster list`, `k3d node list`, `k3d registry list`
Stop and start        | `k3d cluster stop <name>`, `k3d cluster start <name>`
Kubeconfig            | `k3d kubeconfig get <name>`, `k3d kubeconfig merge <name> --kubeconfig-switch-context`
Delete                | `k3d cluster delete <name>`, `--all`, `k3d registry delete k3d-<name>`

---

## Where things are

What                    | Where
------------------------|---------------------------------------------------------------------------------------------------------
Nodes                   | Containers named `k3d-<cluster>-server-<n>` and `k3d-<cluster>-agent-<n>`
Load balancer           | The container `k3d-<cluster>-serverlb`, an nginx, with `/etc/nginx/nginx.conf`
Network                 | `k3d-<cluster>`, one per cluster
Context of kubectl      | `k3d-<cluster>`, in the default kubeconfig
Registries of the nodes | `/etc/rancher/k3s/registries.yaml`, in each node ([registries](https://k3d.io/stable/usage/registries/))
Volumes of `local-path` | `/var/lib/rancher/k3s/storage`, in each node
The machine, from a Pod | `host.k3d.internal`

---

## Tips

- **Keep the cluster in a file** in the repository, with the version of the k3s image, so every developer and the pipeline create the same cluster.

- **Pin the image of the nodes**: k3d has a default k3s version of its own, which `k3d version` prints, and it changes with the release.

- **Publish the ports needed at creation**, and keep a registry for the images built on the machine.

- **Use Deployments, not bare Pods**: stopping a cluster drains its server, which deletes the Pods that no controller owns.

- **Delete a cluster rather than repair it**: it takes seconds, and a script that creates one is the documentation of the setup.

- **Keep a cluster idle only when needed**: `k3d cluster stop` frees the CPU and keeps the state.

- **Name the contexts**: with several clusters, check `kubectl config current-context` before a command that changes something.

---

## Good practices

- Treat the cluster as disposable: no data that matters inside it.

- Do not run untrusted code on it: the nodes are privileged containers of the machine.

- Do not use it as a model of production for storage, load balancing or high availability, which a k3d cluster on one machine cannot show.

- Keep the same manifests for k3d and for the real cluster, and put the differences in values: the ingress class, the storage class, the registry name.

- Update k3d and the k3s image together, and read the release notes: the config format is alpha.

---

## Natural next steps

Need                        | Next
----------------------------|-----------------------------------------------------------------------------
HTTP routes to the Services | **An ingress controller**: Traefik configured, or replaced, on a k3d cluster
The state in Git            | **GitOps**, with **Argo CD** or **Flux**, on a cluster created from a file
Many clusters               | **Rancher**, which manages k3s and other clusters
Network and workload rules  | **Zero trust** and **NeuVector**
A cluster on real machines  | **k3s** on virtual machines, as in the k3s course

- Reference: [k3d documentation](https://k3d.io/stable/), [k3s documentation](https://docs.k3s.io/), [Kubernetes documentation](https://kubernetes.io/docs/home/).
