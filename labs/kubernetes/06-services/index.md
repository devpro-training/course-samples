# Services

The Pods of a Deployment come and go, and each new one has a new address.
A Service gives them one name and one address, and sends each connection to one of the Pods that are ready.

## A Service

1. Write the manifest.
   The `selector` is a label query: every Pod that carries `app: web` is a backend:

   ```bash exec target=kube
   mkdir -p ~/lab/services && cd ~/lab/services && \
   tee service.yaml <<EOT
   apiVersion: v1
   kind: Service
   metadata:
     name: web
   spec:
     selector:
       app: web
     ports:
       - port: 80
         targetPort: 80
   EOT
   ```

2. Apply it, and list the Services:

   <!-- verify: expect="ClusterIP" -->

   ```bash exec target=kube
   cd ~/lab/services && kubectl apply -f service.yaml && kubectl get service web
   ```

3. The backends are the addresses of the Pods, kept by the control plane in an EndpointSlice:

   <!-- verify: expect="IPv4" -->

   ```bash exec target=kube
   kubectl get endpointslice --selector kubernetes.io/service-name=web
   ```

4. The labels are the link between the Service and the Pods:

   <!-- verify: expect="pod-template-hash" -->

   ```bash exec target=kube
   kubectl get pods --show-labels
   ```

## A name in the cluster

1. Run a Pod for one command, which asks the address of the Service.
   `kubectl run --rm` removes the Pod when the command ends, and the cluster DNS answers `<service>.<namespace>.svc.cluster.local`.
   The final dot makes the name complete, so the resolver does not try the search domains of the Pod first:

   <!-- verify: requires=network timeout=180 expect="10.43." -->

   ```bash exec target=kube
   kubectl run client --rm -i --restart=Never --image="${BUSYBOX_IMAGE}" -- nslookup web.default.svc.cluster.local.
   ```

2. Fetch the page by that name, twelve times:

   <!-- verify: timeout=120 expect="Welcome to nginx!" -->

   ```bash exec target=kube
   kubectl run client --rm -i --restart=Never --image="${BUSYBOX_IMAGE}" -- \
     sh -c 'for i in $(seq 1 12); do wget -qO- http://web | head -n 4 | tail -n 1; done' 2>&1 | sort | uniq -c
   ```

3. The log of each Pod counts the requests it received, so the Service spread them:

   <!-- verify: expect="pod/web-" -->

   ```bash exec target=kube
   for p in $(kubectl get pods --selector app=web -o name); do echo "$p $(kubectl logs "$p" | grep -c 'GET / HTTP')"; done
   ```

## A port on the node

A `ClusterIP` Service is reachable inside the cluster only.
A `NodePort` Service also opens a port on every node, and a `LoadBalancer` Service asks for an address from the platform: a cloud load balancer on a managed service, ServiceLB in k3s.

1. Add a `NodePort` Service on port 30080, and call it from the machine, which is the node:

   <!-- verify: timeout=60 expect="Welcome to nginx!" -->

   ```bash exec target=kube
   cd ~/lab/services && \
   tee nodeport.yaml <<EOT
   apiVersion: v1
   kind: Service
   metadata:
     name: web-node
   spec:
     type: NodePort
     selector:
       app: web
     ports:
       - port: 80
         nodePort: 30080
   EOT
   kubectl apply -f nodeport.yaml && \
   for i in $(seq 1 15); do wget -qO- http://127.0.0.1:30080 && break; sleep 1; done
   ```

   An ingress controller, in a later course, shares one address between many Services by host name and path.
