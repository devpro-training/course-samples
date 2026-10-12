# Bundled components

Upstream Kubernetes leaves the ingress, the load balancer and the storage to the operator.
k3s starts with them, so the cluster is usable at once, and each one can be removed.

## What the server deploys

1. Wait for the packaged components, then list them.
   Traefik arrives last, since its chart is installed by a Job:

   <!-- verify: timeout=300 expect="Completed" -->

   ```bash exec target=kube
   for i in $(seq 1 150); do kubectl get pods --namespace kube-system --no-headers 2> /dev/null | grep -E "^svclb-traefik.* Running" && break; sleep 2; done; \
   kubectl get pods --namespace kube-system
   ```

Component                | Does                                                          | Disabled with
-------------------------|---------------------------------------------------------------|-----------------
`coredns`                | Cluster DNS: a Service has a name                             | `coredns`
`local-path-provisioner` | Storage: a volume is a folder of the node                     | `local-storage`
`metrics-server`         | Usage of CPU and memory, for `kubectl top` and autoscaling    | `metrics-server`
`traefik`                | Ingress controller: HTTP routes to Services                   | `traefik`
`svclb-traefik`          | ServiceLB: a `LoadBalancer` Service on the ports of the nodes | `servicelb`

2. The server reads its manifests from a folder, and applies them again when a file changes.
   Each file is tracked as an `AddOn` object:

   <!-- verify: expect="traefik.yaml" -->

   ```bash exec target=kube
   ls /var/lib/rancher/k3s/server/manifests && kubectl get addons --namespace kube-system --output name
   ```

3. Traefik and its definitions are Helm charts, deployed by the Helm controller of k3s from `HelmChart` objects:

   <!-- verify: expect="traefik-crd" -->

   ```bash exec target=kube
   kubectl get helmcharts --namespace kube-system
   ```

## Storage

1. The default storage class is `local-path`:

   <!-- verify: expect="local-path (default)" -->

   ```bash exec target=kube
   kubectl get storageclass
   ```

2. A claim and a Pod that writes to it:

   <!-- verify: requires=network timeout=240 expect="condition met" -->

   ```bash exec target=kube
   mkdir -p ~/lab/storage && cd ~/lab/storage && \
   tee volume.yaml <<EOT
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: data
   spec:
     accessModes: [ReadWriteOnce]
     resources:
       requests:
         storage: 100Mi
   ---
   apiVersion: v1
   kind: Pod
   metadata:
     name: writer
   spec:
     containers:
       - name: writer
         image: ${BUSYBOX_IMAGE}
         command: ["sh", "-c", "echo stored on the node > /data/hello.txt && sleep 3600"]
         volumeMounts:
           - name: data
             mountPath: /data
     volumes:
       - name: data
         persistentVolumeClaim:
           claimName: data
   EOT
   kubectl apply -f volume.yaml && \
   kubectl wait --for=condition=Ready pod/writer --timeout=200s
   ```

   The claim stays `Pending` until a Pod uses it: the volume is created on the node where the Pod is placed.

3. The volume is a folder of that node, so it is not replicated and it does not follow the Pod to another node:

   <!-- verify: expect="stored on the node" -->

   ```bash exec target=kube
   kubectl get pvc data && cat /var/lib/rancher/k3s/storage/pvc-*/hello.txt
   ```

## Ingress and load balancer

1. Traefik listens on the ports 80 and 443 of the node, through ServiceLB, with no route yet:

   <!-- verify: timeout=240 expect="404 page not found" -->

   ```bash exec target=kube
   kubectl rollout status deployment/traefik --namespace kube-system --timeout=200s && \
   kubectl get service --namespace kube-system traefik && \
   { wget --content-on-error -qO- http://127.0.0.1/ || true; }
   ```

   Traefik answers `404` because no route exists yet, and `wget` exits with an error status on it, which `|| true` ignores.

## Metrics

1. The usage of the node, from `metrics-server`:

   <!-- verify: timeout=180 expect="CPU(cores)" -->

   ```bash exec target=kube
   for i in $(seq 1 60); do kubectl top nodes 2> /dev/null && break; sleep 3; done; kubectl top nodes
   ```

## Remove a component

A file `/etc/rancher/k3s/config.yaml` holds the options of `k3s server`, one key per flag.
It is read when the server starts.

1. Disable Traefik and ServiceLB, since this cluster will get another ingress later:

   ```bash exec target=kube
   mkdir -p /etc/rancher/k3s && \
   tee /etc/rancher/k3s/config.yaml <<'EOT'
   disable:
     - traefik
     - servicelb
   EOT
   ```

   [Configuration file](https://docs.k3s.io/installation/configuration), [packaged components](https://docs.k3s.io/installation/packaged-components).

2. Restart the server.
   The Pods keep running while it is stopped:

   ```bash exec target=kube
   pkill -f "^k3s server"; sleep 5
   ```

   ```bash exec target=kube
   nohup k3s server > /var/log/k3s.log 2>&1 &
   ```

3. Wait until the components are gone.
   The server deletes the Pods, the objects and the manifest of what it disables, and the Jobs that installed the charts stay as `Completed`:

   <!-- verify: timeout=240 expect="manifests with traefik: 0" -->

   ```bash exec target=kube
   until kubectl get --raw /readyz > /dev/null 2>&1; do sleep 2; done; \
   for i in $(seq 1 60); do kubectl get pods --namespace kube-system --no-headers | grep -qE "^(traefik|svclb-traefik)-" || break; sleep 3; done; \
   kubectl get pods --namespace kube-system; \
   echo "manifests with traefik: $(ls /var/lib/rancher/k3s/server/manifests | grep -c traefik)"
   ```

   Nothing listens on the port 80 now:

   <!-- verify: expect="Connection refused" -->

   ```bash exec target=kube
   { wget -T 3 -t 1 -O- http://127.0.0.1/ || true; } 2>&1 | grep -i refused
   ```
