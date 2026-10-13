# Storage

k3s ships a storage class, `local-path`, whose volumes are folders of the node.
In k3d the node is a container, so the folder is inside the container, and what happens to the data follows from that.

## The default storage class

1. Create a cluster of one server and two agents, and wait for the storage class:

   <!-- verify: requires=network timeout=300 expect="local-path (default)" -->

   ```bash exec target=docker
   k3d cluster create dev --image "${NODE_IMAGE}" --agents 2 && \
   for i in $(seq 1 60); do kubectl get storageclass --no-headers 2> /dev/null | grep -q local-path && break; sleep 2; done; \
   kubectl get storageclass
   ```

   The volume binding mode is `WaitForFirstConsumer`: a claim stays `Pending` until a Pod uses it, since the folder is created on the node where the Pod is placed.

2. A claim, and a Deployment whose Pod adds a line to a file of the volume each time it starts:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=docker
   mkdir -p ~/lab/storage && cd ~/lab/storage && \
   tee app.yaml <<EOT
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
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: app
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: app
     template:
       metadata:
         labels:
           app: app
       spec:
         containers:
           - name: app
             image: ${BUSYBOX_IMAGE}
             command: ["sh", "-c", "echo started >> /data/log.txt && sleep 3600"]
             volumeMounts:
               - name: data
                 mountPath: /data
         volumes:
           - name: data
             persistentVolumeClaim:
               claimName: data
   EOT
   kubectl apply -f app.yaml && \
   kubectl rollout status deployment/app --timeout=200s
   ```

## Where the data is

1. The volume is tied to one node, the one the Pod was placed on:

   <!-- verify: expect="k3d-dev-" -->

   ```bash exec target=docker
   kubectl get pvc data && \
   kubectl get pv --output jsonpath='{.items[0].spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}{"\n"}'
   ```

2. The folder is in the container of that node, under `/var/lib/rancher/k3s/storage`, which is on a Docker volume:

   <!-- verify: expect="_default_data" -->

   ```bash exec target=docker
   NODE=$(kubectl get pod --selector app=app --output jsonpath='{.items[0].spec.nodeName}') && \
   docker exec "${NODE}" ls /var/lib/rancher/k3s/storage && \
   docker inspect "${NODE}" --format '{{range .Mounts}}{{if eq .Destination "/var/lib/rancher/k3s"}}{{.Type}} {{.Destination}}{{end}}{{end}}'
   ```

## What survives

1. Delete the Pod.
   The claim and the volume stay, the Deployment creates another Pod, the scheduler places it on the node that holds the folder, and the file has a second line:

   <!-- verify: timeout=300 expect="runs: 2" -->

   ```bash exec target=docker
   kubectl delete pod --selector app=app --wait > /dev/null && \
   for i in $(seq 1 60); do [ "$(timeout 20 kubectl exec deployment/app -- cat /data/log.txt 2> /dev/null | wc -l)" -ge 2 ] && break; sleep 3; done; \
   echo "runs: $(timeout 20 kubectl exec deployment/app -- cat /data/log.txt | wc -l)"
   ```

2. Stop the cluster and start it again.
   The containers of the nodes are the same ones, with their volumes, so the objects of the cluster and the data stay, and the file has a third line:

   <!-- verify: timeout=400 expect="runs: 3" -->

   ```bash exec target=docker
   k3d cluster stop dev && k3d cluster start dev && \
   for i in $(seq 1 80); do [ "$(timeout 20 kubectl exec deployment/app -- cat /data/log.txt 2> /dev/null | wc -l)" -ge 3 ] && break; sleep 3; done; \
   echo "runs: $(timeout 20 kubectl exec deployment/app -- cat /data/log.txt | wc -l)"
   ```

3. A Deployment was needed for that.
   When a server stops, the entrypoint that k3d adds to its container drains the node first, with `--force` and `--disable-eviction`, which deletes the Pods that no controller owns.
   A Pod created alone with `kubectl run` on the server does not come back after a stop, and a Pod of a Deployment is created again.
   The Pods of the agents are not drained, as the script says:

   <!-- verify: expect="--disable-eviction" -->

   ```bash exec target=docker
   docker exec k3d-dev-server-0 grep "kubectl drain" /bin/k3d-entrypoint.sh
   ```

4. Delete the cluster.
   The data was in the volumes of the nodes, and k3d deletes them with the nodes:

   <!-- verify: expect="volumes left: 0" -->

   ```bash exec target=docker
   k3d cluster delete dev > /dev/null 2>&1; \
   echo "volumes left: $(docker volume ls --quiet | wc -l)"
   ```

Event                  | Data of a `local-path` volume | A Pod with no controller
-----------------------|-------------------------------|------------------------------
A Pod is deleted       | Kept                          | Gone, as any deleted Pod
The cluster is stopped | Kept                          | Deleted if it was on a server
The cluster is deleted | Lost                          | Lost

## Keep the data on the machine

A folder of the machine, mounted on the storage path of the nodes, outlives the cluster.
`--volume <folder>:<path>@all` mounts it in every node.

1. Create the cluster with the folder, and run the same Deployment:

   <!-- verify: requires=network timeout=300 expect="successfully rolled out" -->

   ```bash exec target=docker
   mkdir -p ~/lab/storage/keep && cd ~/lab/storage && \
   k3d cluster create dev --image "${NODE_IMAGE}" --volume "${HOME}/lab/storage/keep:/var/lib/rancher/k3s/storage@all" > /dev/null 2>&1 && \
   for i in $(seq 1 60); do kubectl get storageclass --no-headers 2> /dev/null | grep -q local-path && break; sleep 2; done; \
   kubectl apply -f app.yaml > /dev/null && \
   kubectl rollout status deployment/app --timeout=200s
   ```

2. The file is on the machine, and stays after the cluster is deleted:

   <!-- verify: expect="started" -->

   ```bash exec target=docker
   k3d cluster delete dev > /dev/null 2>&1; \
   cat ~/lab/storage/keep/pvc-*/log.txt
   ```

   A new cluster creates new volumes with new names, so it does not reattach the folder by itself.
   The folder is data to read, copy, or declare as a volume, and the way to keep an application running through a deletion is a database or an object store outside the cluster.

> [!NOTE]
> On Docker Desktop, the folder must be one that Docker Desktop shares with its virtual machine, which its settings list under **Resources > File sharing**.
> Docker's documentation names a named Docker volume as the better choice for databases and caches.
