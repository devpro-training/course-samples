# k3s

Kubernetes in one binary.

---

## What k3s is

- **A conformant Kubernetes distribution**: the documentation calls it "a fully compliant Kubernetes distribution", with the same API as any other.

- **One binary of less than 100 MB**, which the lab downloads and weighs.

- **Half the memory**: "Easy to install, half the memory, all in a binary of less than 100 MB".

- **A name that is a joke about size**: Kubernetes has 10 letters, k3s 5, and the README adds that a 3 is an 8 cut in half.

- **Open source, Apache 2.0**, in the repository [k3s-io/k3s](https://github.com/k3s-io/k3s).

- The Kubernetes course ran it as a tool, this course is about k3s itself.

- References: [k3s documentation](https://docs.k3s.io/), [README](https://github.com/k3s-io/k3s).

---

## Where it comes from

Date                 | Event
---------------------|------------------------------------------------------------------
February 2019        | Rancher Labs announces k3s, a Kubernetes for the edge and constrained machines
November 2019        | General availability, announced by Rancher Labs
19 August 2020       | k3s is accepted by the CNCF, at the **Sandbox** maturity level
1 December 2020      | SUSE completes the acquisition of Rancher Labs

- k3s was the second project Rancher gave to the CNCF, after Longhorn.

- SUSE says k3s was donated to the CNCF in June 2020, the CNCF page gives the acceptance date, and the two are not the same event.

- Rancher is now a part of **SUSE**, which calls itself "a major contributor to the project", and sells up to five years of support for k3s with SUSE Rancher Prime.

- The CNCF page of the project states the Sandbox level: the first of the three levels of the CNCF (sandbox, incubating, graduated), where a project is hosted by the foundation while it matures.

- References: [CNCF project page](https://www.cncf.io/projects/k3s/),
  [SiliconANGLE, 26 August 2020](https://siliconangle.com/2020/08/26/rancher-labs-k3s-becomes-latest-cncf-sandbox-project/),
  [SiliconANGLE, 1 December 2020](https://siliconangle.com/2020/12/01/suse-completes-acquisition-rancher-labs/),
  [Help Net Security, 22 November 2019](https://www.helpnetsecurity.com/2019/11/22/rancher-labs-k3s-rio/),
  [SUSE k3s](https://www.suse.com/products/k3s/).

---

## One binary

![A k3s server holds the control plane, the datastore, a node and the packaged components, and a k3s agent holds a node, joined to the server on TCP 6443 with VXLAN on UDP 8472](../assets/k3s-binary-dark.svg#gh-dark-mode-only)
![A k3s server holds the control plane, the datastore, a node and the packaged components, and a k3s agent holds a node, joined to the server on TCP 6443 with VXLAN on UDP 8472](../assets/k3s-binary.svg#gh-light-mode-only)

---

## Why it is interesting

Need                  | What k3s gives
----------------------|--------------------------------------------------------------
Small machines        | A server asks for 2 cores and 2 GiB, an agent for 1 core and 512 MiB
Edge, IoT, ARM        | x86_64, armhf and arm64, on most modern Linux distributions
Install in a minute   | A script, or a binary and a command, and a working cluster
Development and CI    | A real cluster in seconds on a laptop or in a pipeline, then the same manifests in production
Offline sites         | Air-gapped installation, and a registry mirror shared between the nodes (Spegel)
No expert at hand     | Defaults that work: DNS, storage, ingress, load balancer, metrics
Embedding             | A cluster inside a product, since it is one file and a few options

- The requirements are a modern kernel and cgroup mounts, nothing else.

- Reference: [requirements](https://docs.k3s.io/installation/requirements).

---

## What was changed from upstream

- **One process**: the API server, the scheduler and the controller manager run inside `k3s server`, and `kubelet` and `containerd` inside both `server` and `agent`.

- **SQLite by default**, behind **Kine**, instead of etcd.

- **Two things removed** to shrink the binary: the in-tree storage drivers and the in-tree cloud provider, whose replacements (CSI and CCM) work in k3s.

- **Almost no patches**: the README says "well under 1000 lines", and that k3s "explicitly intends not to change any core Kubernetes functionality".

- **Batteries included**, and each one can be turned off: see the next slides.

- **Upstream behavior kept**: the API is the same, and the cluster passes the conformance tests.

- References: [k3s architecture](https://docs.k3s.io/architecture), [README](https://github.com/k3s-io/k3s).

---

## SQLite and the datastore

- **Kubernetes keeps its objects in etcd**, which needs memory, disk latency and, for a safe cluster, three members.

- **k3s keeps them in SQLite** with one server: one file, `/var/lib/rancher/k3s/server/db/state.db`, with no other process to run.

- **Kine** answers the part of the etcd API that the API server needs, on top of SQLite, MySQL, MariaDB or PostgreSQL.

Cluster                       | Datastore                      | Chosen with
------------------------------|--------------------------------|---------------------------
One server                    | SQLite (default)               | nothing
Several servers (3 or more)   | Embedded etcd                  | `--cluster-init`, then `--server`
Several servers (2 or more)   | An external database           | `--datastore-endpoint`

- A backup of SQLite is a copy of the `db` folder, and of the token.

- SQLite cannot be shared between servers, and a single-server cluster is converted to embedded etcd by restarting its server with `--cluster-init`, as the [high availability page](https://docs.k3s.io/datastore/ha-embedded) says.

- References: [datastore](https://docs.k3s.io/datastore), [backup and restore](https://docs.k3s.io/datastore/backup-restore), [Kine](https://github.com/k3s-io/kine).

---

## What it installs

Component               | Role                        | Packaged as
------------------------|-----------------------------|----------------------------------
containerd              | Container runtime           | In the binary
Flannel                 | Pod network (VXLAN)         | In the binary
Network policy controller | Enforces `NetworkPolicy`  | In the binary
CoreDNS                 | DNS of the cluster          | Manifest
Traefik                 | Ingress controller          | Helm chart
ServiceLB               | `LoadBalancer` Services on the nodes | In the binary
local-path-provisioner  | Storage: folders of the node | Manifest
metrics-server          | `kubectl top`, autoscaling  | Manifest
Helm controller         | Installs `HelmChart` objects | In the binary

- A manifest in `/var/lib/rancher/k3s/server/manifests` is applied when the server starts and when it changes.

- Each component is turned off with `--disable=<name>`, or `disable:` in the configuration file.

- References: [packaged components](https://docs.k3s.io/installation/packaged-components), [networking services](https://docs.k3s.io/networking/networking-services), [Helm](https://docs.k3s.io/add-ons/helm).

---

## Install

```bash
curl -sfL https://get.k3s.io | sh -
```

- The script verifies the checksum of the binary, creates a **systemd or OpenRC service**, links `kubectl`, `crictl` and `ctr`, and writes `k3s-killall.sh` and `k3s-uninstall.sh`.

- Options go in environment variables (`INSTALL_K3S_VERSION`, `INSTALL_K3S_CHANNEL`, `INSTALL_K3S_EXEC`, `K3S_TOKEN`, `K3S_URL`) or in `/etc/rancher/k3s/config.yaml`, which survives an upgrade.

- **Join an agent**: `K3S_URL=https://<server>:6443 K3S_TOKEN=<token>` in the same command.

- **By hand**: download the binary and its `sha256sum-amd64.txt` from the release, as the lab does.

- A [configuration file](https://docs.k3s.io/installation/configuration) holds one key per flag, in `/etc/rancher/k3s/config.yaml` and `config.yaml.d/*.yaml`.

- Reference: [quick start](https://docs.k3s.io/quick-start), [configuration](https://docs.k3s.io/installation/configuration).

---

## Day two

Operation   | How
------------|-----------------------------------------------------------------------
Upgrade     | Servers first, one at a time, then the agents: the script with a version, a new binary, or the system-upgrade-controller
Scale       | `k3s agent` with the address of a server and the token
Back up     | SQLite: copy `db/` and the token. Embedded etcd: `k3s etcd-snapshot`
Remove      | Delete the node from the cluster, then `k3s-agent-uninstall.sh` or `k3s-uninstall.sh`
Harden      | A hardening guide of the documentation for the CIS benchmark, measured with kube-bench

- A channel is a stream of releases: `stable` is the default, `latest` is the newest, and `v1.36` follows one minor version.

- Reference: [upgrades](https://docs.k3s.io/upgrades), [uninstall](https://docs.k3s.io/installation/uninstall), [hardening guide](https://docs.k3s.io/security/hardening-guide).

---

## Harden: the CIS benchmark

- **The CIS Kubernetes Benchmark** is a list of checks on the settings of the control plane, the nodes, the policies and the permissions of files.

- **K3s passes many checks by default**, since its components are not Pods with files to protect.

- **The hardening guide** changes the host (kernel parameters), the options of k3s (`protect-kernel-defaults`, `secrets-encryption`, audit logs, admission configuration), and the policies (Pod Security, network policies).

- **kube-bench** (Aqua Security) runs the checks on a node, with a profile per distribution, `k3s-cis-1.9` for example, and prints `PASS`, `FAIL`, `WARN` and `INFO` with the remediation.

- The guide warns that some controls restrict the cluster: a policy of `restricted` refuses most public images.

- The lab measures, hardens, and measures again.

---

## In this lab

Step               | What it shows
-------------------|------------------------------------------------------------------
Setup              | The binary of the release, checked against its checksum, and a running server
Install            | The install script and why it stops here, what the binary carries, the files, the datastore options
Bundled components | CoreDNS, local-path, Traefik, ServiceLB and metrics-server, then Traefik and ServiceLB removed with the configuration file
Harden             | kube-bench before and after the hardening guide
Upgrade            | A backup, a new binary, a restart, the workload untouched
Scale              | An agent joins with a token, and receives Pods
Remove             | Drain, delete the node, and what the removal scripts do

> Two virtual machines and no account: the binaries come from GitHub, and the images from Docker Hub, which allow anonymous downloads.
