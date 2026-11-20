# The cluster

Everything in Kubernetes goes through its API, and `kubectl` is the client of that API.
The commands below read what the server of the previous step started.

## Node and version

1. List the nodes.
   This cluster has one, which carries the role of the control plane and runs the workloads as well:

   <!-- verify: expect="containerd://" -->

   ```bash exec target=kube
   kubectl get nodes -o wide
   ```

2. Ask the version of the client and of the server, and the version of Go that built them:

   <!-- verify: expect="go1." -->

   ```bash exec target=kube
   kubectl version -o json | grep -E '"(gitVersion|goVersion)"'
   ```

## The system Pods

A namespace separates the objects of a cluster into groups.
Kubernetes starts its own components in `kube-system`.

1. List the namespaces:

   <!-- verify: expect="kube-node-lease" -->

   ```bash exec target=kube
   kubectl get namespaces
   ```

2. Wait until the DNS server of the cluster is ready, then list the system Pods.
   `kubectl wait` returns when the condition is true:

   <!-- verify: timeout=240 expect="coredns" -->

   ```bash exec target=kube
   until kubectl get pods --namespace kube-system --selector k8s-app=kube-dns --no-headers 2> /dev/null | grep -q .; do sleep 2; done; \
   kubectl wait --namespace kube-system --for=condition=Ready pod --selector k8s-app=kube-dns --timeout=200s && \
   kubectl get pods --namespace kube-system
   ```

   There is no Pod for the API server, the scheduler or the controller manager: k3s runs them inside its own process, where kubeadm clusters run them as Pods.

3. The process of the server, the container runtime it started, and one shim per running Pod:

   <!-- verify: expect="k3s-server" -->

   ```bash exec target=kube
   ps -eo pid,comm | grep -E "k3s|containerd"
   ```

## The API

1. The API is a list of kinds of objects.
   A Pod, a Service or a node is one of them, and the last column says whether it lives in a namespace:

   <!-- verify: expect="configmaps" -->

   ```bash exec target=kube
   kubectl api-resources | head -n 14
   ```

2. The server also answers a plain HTTP request, which `kubectl` signs with the credentials of the kubeconfig:

   <!-- verify: expect="ConfigMap" -->

   ```bash exec target=kube
   kubectl get --raw /api/v1 | python3 -c "import json,sys; print([r['kind'] for r in json.load(sys.stdin)['resources']][:8])"
   ```

## The datastore

The API server keeps every object in a datastore.
k3s uses SQLite by default, behind Kine, and the file is on the machine.

1. Read the namespaces of the cluster in it.
   Each row of the `kine` table is a revision of a key, and the keys are the ones etcd would hold:

   <!-- verify: expect="registry/namespaces/kube-system" -->

   ```bash exec target=kube
   ls -lh /var/lib/rancher/k3s/server/db/state.db && python3 - <<'EOT'
   import sqlite3
   db = sqlite3.connect("file:/var/lib/rancher/k3s/server/db/state.db?mode=ro", uri=True)
   rows = db.execute("select name, value from kine where deleted = 0 and name like '/registry/namespaces/%' order by name")
   for name, value in rows:
       print(name, len(value), "bytes, starts with", value[:4])
   EOT
   ```

   The value is the object in the binary format Kubernetes uses for its storage, which starts with `k8s`.

2. The whole cluster is in that table.
   The kinds of objects it holds, with the number of keys of each:

   <!-- verify: expect="clusterroles" -->

   ```bash exec target=kube
   python3 - <<'EOT'
   import sqlite3
   db = sqlite3.connect("file:/var/lib/rancher/k3s/server/db/state.db?mode=ro", uri=True)
   rows = db.execute("""select substr(name, 11, instr(substr(name, 11), '/') - 1) as kind, count(*)
                        from kine where deleted = 0 and id in (select max(id) from kine group by name)
                        group by kind order by 2 desc limit 8""")
   for kind, count in rows:
       print(count, kind)
   EOT
   ```
