# Remove

A node leaves the cluster in two steps: the cluster forgets it, then the machine is cleaned.

## Remove the agent

1. Drain the node, so its Pods are moved, then delete the node.
   The server deletes the secret of its password with it, which is what allows the name to be reused:

   <!-- verify: timeout=240 expect="deleted" -->

   ```bash exec target=kube
   kubectl drain agent --ignore-daemonsets --delete-emptydir-data --timeout=200s && \
   kubectl delete node agent
   ```

2. The cluster is one node again, and the Pods of the deployment are back on it:

   <!-- verify: timeout=120 expect="agent secrets: 0" -->

   ```bash exec target=kube
   kubectl rollout status deployment/web --timeout=100s && kubectl get nodes && \
   echo "agent secrets: $(kubectl get secrets --namespace kube-system --no-headers | grep -c '^agent' || true)"
   ```

## Clean a machine

The install script wrote two scripts for this: `k3s-killall.sh` stops k3s and everything it started, and `k3s-uninstall.sh` runs it and deletes the files.
On an agent, the script is `k3s-agent-uninstall.sh`.
With a service, the scripts stop it first, and this machine has none, so the process is stopped by hand.
The scripts leave `/etc/rancher/node`, the password of the node, and a machine without an init system keeps the `<defunct>` entries of the processes they killed, since nothing reads their exit status.

1. Read what the script does on the agent, then run it:

   <!-- verify: expect="rm -rf /var/lib/kubelet" -->

   ```bash exec target=agent
   grep -h "^rm\|^do_unmount\|^remove_interfaces" /usr/local/bin/k3s-killall.sh /usr/local/bin/k3s-agent-uninstall.sh
   ```

   <!-- verify: timeout=120 expect="k3s files: 0" -->

   ```bash exec target=agent
   pkill -f "^k3s agent"; sleep 3; \
   k3s-agent-uninstall.sh > ~/lab/uninstall.log 2>&1; \
   echo "k3s files: $(ls -d /etc/rancher/k3s /var/lib/rancher/k3s /usr/local/bin/k3s 2> /dev/null | wc -l), processes: $(ps -eo stat=,args= | grep -v '^Z' | grep -c '[k]3s\|[c]ontainerd-shim\|[n]ginx')"
   ```

2. The same on the server, which deletes the cluster with its datastore:

   <!-- verify: timeout=120 expect="k3s files: 0" -->

   ```bash exec target=kube
   pkill -f "^k3s server"; sleep 3; \
   k3s-uninstall.sh > ~/lab/uninstall.log 2>&1; \
   echo "k3s files: $(ls -d /etc/rancher/k3s /var/lib/rancher/k3s /usr/local/bin/k3s 2> /dev/null | wc -l), processes: $(ps -eo stat=,args= | grep -v '^Z' | grep -c '[k]3s\|[c]ontainerd-shim\|[n]ginx')"
   ```

3. The service file of the install script was removed with them, and the network interfaces of k3s are gone:

   <!-- verify: expect="interfaces: 0" -->

   ```bash exec target=kube
   ls /etc/systemd/system/ | grep -c k3s; echo "interfaces: $(ls /sys/class/net | grep -c 'cni0\|flannel')"
   ```

Two things stay on purpose: data outside k3s, an external database or a volume of another storage, and the host settings made for the hardening (`/etc/sysctl.d/90-kubelet.conf`), which k3s never touched on its own.
