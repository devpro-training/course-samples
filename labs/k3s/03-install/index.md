# Install

The previous step installed k3s from the binary of the release.
The documented way is a script, which does more: it also creates a service, and the scripts that stop and remove k3s.

## The install script

1. Download the script of the quick start, and read the stages it runs:

   <!-- verify: requires=network expect="download_and_verify" -->

   ```bash exec target=kube
   mkdir -p ~/lab && cd ~/lab && \
   wget -q "${K3S_INSTALL_URL}" -O install.sh && \
   sed -n '/^# --- run the install process/,$p' install.sh
   ```

   It checks the system, downloads the binary and compares it with the published checksum, links `kubectl`, `crictl` and `ctr` to it, writes the killall and uninstall scripts, and creates and starts a systemd or OpenRC service.

2. Run it.
   This machine runs no init system, so the script is asked not to download the binary again (it is installed already), and not to enable or start a service.
   Everything else it does is done:

   <!-- verify: expect="Creating uninstall script" -->

   ```bash exec target=kube
   cd ~/lab && INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_ENABLE=true INSTALL_K3S_SKIP_START=true sh install.sh
   ```

   On a workstation or a server, the same script with no option downloads the binary of the stable channel, and the service restarts k3s with the machine.
   `K3S_URL`, the address of a server, makes it install an agent.

3. The service file it wrote, and the scripts it created:

   <!-- verify: expect="ExecStart=/usr/local/bin/k3s" -->

   ```bash exec target=kube
   grep -E "^(ExecStart|EnvironmentFile|Restart)=" /etc/systemd/system/k3s.service && ls -l /usr/local/bin/ | grep -E "k3s-|crictl|ctr"
   ```

   The options of the service are the arguments of `ExecStart`, and the `K3S_` variables of the shell are saved in a file that only root reads.
   The scripts are used by the Remove step.

## What the binary carries

1. One file holds the Kubernetes components, the container runtime and the tools around them:

   <!-- verify: expect="etcd-snapshot" -->

   ```bash exec target=kube
   k3s --help | sed -n '/COMMANDS/,/GLOBAL/p'
   ```

2. `crictl` talks to the container runtime of k3s, containerd, with no setting to make.
   It lists the containers of the node, which are the system Pods:

   <!-- verify: timeout=120 expect="kube-system" -->

   ```bash exec target=kube
   for i in $(seq 1 60); do k3s crictl ps 2> /dev/null | grep -q coredns && break; sleep 2; done; \
   k3s crictl ps
   ```

## Where it keeps its files

1. The configuration is under `/etc/rancher/k3s`, and the data under `/var/lib/rancher/k3s`:

   <!-- verify: expect="k3s.yaml" -->

   ```bash exec target=kube
   ls /etc/rancher/k3s /var/lib/rancher/k3s /var/lib/rancher/k3s/server
   ```

   `manifests` holds what the server deploys by itself, `db` the datastore, `tls` the certificates and `token` the secret an agent presents to join.

2. The datastore is SQLite, one file and its journal, behind Kine:

   <!-- verify: expect="state.db" -->

   ```bash exec target=kube
   ls -lh /var/lib/rancher/k3s/server/db/
   ```

3. Embedded etcd and an external database are options of the server, and they are chosen when the cluster is created:

   <!-- verify: expect="embedded Etcd" -->

   ```bash exec target=kube
   k3s server --help | grep -E "^\s+--(cluster-init|datastore-endpoint)"
   ```
