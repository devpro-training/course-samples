# Summary

---

## Cheat sheet

Task                      | Command
--------------------------|------------------------------------------------------------------
Start a server            | `k3s server` (a service, with the install script)
Join an agent             | `k3s agent --server https://<server>:6443 --token <token>`
Use the cluster           | `k3s kubectl ...`, or a link named `kubectl`
Containers of the node    | `k3s crictl ps`, `k3s ctr`
Disable a component       | `disable: [traefik]` in `config.yaml`, or `--disable=traefik`
Deploy with the server    | A file in `/var/lib/rancher/k3s/server/manifests`
Encrypt the Secrets       | `secrets-encryption: true`, then `k3s secrets-encrypt status`
Back up (SQLite)          | Copy `/var/lib/rancher/k3s/server/db` and `.../server/token`
Back up (etcd)            | `k3s etcd-snapshot save`
Upgrade                   | The script with `INSTALL_K3S_VERSION`, or replace the binary and restart
Remove                    | `kubectl drain`, `kubectl delete node`, then `k3s-agent-uninstall.sh` or `k3s-uninstall.sh`

---

## Where things are

What                         | Where
-----------------------------|---------------------------------------------------------------
Configuration                | `/etc/rancher/k3s/config.yaml` and `config.yaml.d/*.yaml` ([documentation](https://docs.k3s.io/installation/configuration))
Kubeconfig of the server     | `/etc/rancher/k3s/k3s.yaml`
Datastore (SQLite)           | `/var/lib/rancher/k3s/server/db/state.db`
Join token                   | `/var/lib/rancher/k3s/server/token`
Manifests of the server      | `/var/lib/rancher/k3s/server/manifests` ([packaged components](https://docs.k3s.io/installation/packaged-components))
Certificates                 | `/var/lib/rancher/k3s/server/tls`
Volumes of `local-path`      | `/var/lib/rancher/k3s/storage`
Registries and mirrors       | `/etc/rancher/k3s/registries.yaml` ([private registry](https://docs.k3s.io/installation/private-registry))
Logs with the install script | `journalctl -u k3s`, and `journalctl -u k3s-agent` on an agent

---

## Tips

- **Keep the options in `config.yaml`**, not in the service file: the script rewrites the service, and the file is kept.

- **Pin the version** (`INSTALL_K3S_VERSION`), and move one minor version at a time, servers first.

- **Back up before an upgrade**: the datastore folder, and the token without which it is unusable.

- **Use a fixed address** for the API server in the certificates and the agents (`tls-san`) before the cluster grows.

- **Do not edit a packaged manifest**, k3s rewrites it at each start: configure Traefik with a `HelmChartConfig`, and disable what is replaced.

- **Convert to embedded etcd** (restart the server with `--cluster-init`) before adding servers: SQLite cannot be shared.

- **Delete a node from the cluster** before reinstalling a machine under the same name, or its stored password refuses it.

---

## Good practices

- Harden with the guide, then measure with kube-bench, and keep the report: the numbers change with the version of the benchmark and of k3s.

- Apply the Pod Security Standards and network policies in every namespace, since the defaults allow everything.

- Keep the configuration and the manifests of the server in Git, and apply them to every server.

- Restrict the VXLAN port, UDP 8472, to the nodes: the documentation says it should not be exposed.

- Treat `local-path` as a development storage: the data lives on one node and is not replicated.

---

## Natural next steps

Need                        | Next
----------------------------|------------------------------------------------------------------
Several clusters on a laptop | **k3d**: k3s nodes in containers, for development and tests
HTTP routes to the Services  | **An ingress controller**: Traefik configured, or replaced
Storage that survives a node | A **CSI driver** with a storage class of its own, replicated (Longhorn, a SUSE project hosted by the CNCF, for example), in place of `local-path`
The state in Git             | **GitOps**, with **Argo CD** or **Flux**
Many clusters                | **Rancher**, which manages k3s and other clusters
Network and workload rules   | **Zero trust** and **NeuVector**
Highly available API         | Three servers with embedded etcd, and a load balancer

- Reference: [k3s documentation](https://docs.k3s.io/), [CIS hardening guide](https://docs.k3s.io/security/hardening-guide), [kube-bench](https://github.com/aquasecurity/kube-bench), [Kubernetes documentation](https://kubernetes.io/docs/home/).
