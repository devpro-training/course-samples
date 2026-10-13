# Reach an application

A Pod has an address that only the cluster can reach, and that changes with the Pod.
A Service gives a stable name and address to a set of Pods, and there are four ways to reach that Service from outside, each with its own limit.

## The cluster

1. Create a cluster.
   Docker publishes the ports 8080 and 8443 of the machine on the load balancer container of k3d, which forwards them to the ports 80 and 443 of the server node, where Traefik listens.
   Nothing else of the cluster is reachable from the machine:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create dev --image "${NODE_IMAGE}" --port "8080:80@loadbalancer" --port "8443:443@loadbalancer"
   ```

2. Wait for Traefik.
   The k3s Helm controller installs it a few seconds after the server starts:

   <!-- verify: timeout=240 expect="successfully rolled out" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl --namespace kube-system get deployment traefik > /dev/null 2>&1 && break; sleep 2; done; \
   kubectl --namespace kube-system rollout status deployment/traefik --timeout=200s
   ```

## A Service is not enough

1. Deploy an application and a Service in front of it.
   `whoami` is a web server that prints the request it receives, which makes routing visible:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=docker
   mkdir -p ~/lab/expose && cd ~/lab/expose && \
   tee shop.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: shop
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: shop
     template:
       metadata:
         labels:
           app: shop
       spec:
         containers:
           - name: shop
             image: ${WHOAMI_IMAGE}
             env:
               - name: WHOAMI_NAME
                 value: shop
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: shop
   spec:
     selector:
       app: shop
     ports:
       - port: 80
   EOT
   kubectl apply -f shop.yaml && \
   kubectl rollout status deployment/shop --timeout=200s
   ```

2. The default type of a Service is `ClusterIP`: an address inside the cluster.
   A Pod reaches the Service by its name:

   <!-- verify: requires=network timeout=120 expect="Name: shop" -->

   ```bash exec target=docker
   cd ~/lab/expose && \
   kubectl run client --image "${BUSYBOX_IMAGE}" --rm --stdin --restart Never -- wget -qO- http://shop/
   ```

3. The machine is outside the cluster, and the address of the Service does not exist on its network:

   <!-- verify: timeout=60 expect="status 4" -->

   ```bash exec target=docker
   wget -qO- --tries 1 --timeout 3 "http://$(kubectl get service shop --output jsonpath='{.spec.clusterIP}')/"; \
   echo "status $?"
   ```

## NodePort and LoadBalancer

- A `NodePort` Service opens the same port, between 30000 and 32767, on every node: it is reached at the address of a node.
- A `LoadBalancer` Service asks the platform for an external address: a cloud load balancer, or ServiceLB in k3s.
- Each Service of these types uses its own port or address, with no name, no path and no certificate: ten applications are ten ports or ten addresses.

1. Change the Service to `NodePort` and call it on the node:

   <!-- verify: timeout=60 expect="Name: shop" -->

   ```bash exec target=docker
   kubectl patch service shop --patch '{"spec":{"type":"NodePort"}}' && \
   kubectl get service shop && \
   wget -qO- "http://$(kubectl get node --output jsonpath='{.items[0].status.addresses[0].address}'):$(kubectl get service shop --output jsonpath='{.spec.ports[0].nodePort}')/"
   ```

2. Put the Service back to `ClusterIP`:

   <!-- verify: expect="service/shop patched" -->

   ```bash exec target=docker
   kubectl patch service shop --patch '{"spec":{"type":"ClusterIP"}}'
   ```

## An Ingress

An Ingress is a list of HTTP rules: for this host and this path, send the request to this Service.
It is only data.
The ingress controller reads it and configures a reverse proxy, which listens on one address for every application.

1. Look at the controller of the cluster, and the class of Ingress it serves:

   <!-- verify: expect="traefik.io/ingress-controller" -->

   ```bash exec target=docker
   kubectl --namespace kube-system get pods --selector app.kubernetes.io/name=traefik && \
   kubectl get ingressclass
   ```

2. Create an Ingress that sends every path to the Service:

   <!-- verify: expect="ingress.networking.k8s.io/shop created" -->

   ```bash exec target=docker
   cd ~/lab/expose && \
   tee ingress.yaml <<EOT
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: shop
   spec:
     rules:
       - http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: shop
                   port:
                     number: 80
   EOT
   kubectl apply -f ingress.yaml
   ```

3. Request the page on the port of the machine:

   <!-- verify: timeout=120 expect="Name: shop" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do wget -qO- http://127.0.0.1:8080/ > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://127.0.0.1:8080/
   ```

   `Host` and `X-Forwarded-For` are the headers the proxy added, and the `RemoteAddr` is the proxy, not the client.

## The controller does the work

1. Stop the controller.
   The Ingress is still there, and nothing answers:

   <!-- verify: timeout=60 expect="status 4" -->

   ```bash exec target=docker
   kubectl --namespace kube-system scale deployment traefik --replicas 0 && \
   kubectl --namespace kube-system wait --for delete pod --selector app.kubernetes.io/name=traefik --timeout 60s; \
   wget -qO- --tries 1 --timeout 3 http://127.0.0.1:8080/; \
   echo "status $?"
   ```

2. Start it again:

   <!-- verify: timeout=120 expect="Name: shop" -->

   ```bash exec target=docker
   kubectl --namespace kube-system scale deployment traefik --replicas 1 && \
   kubectl --namespace kube-system rollout status deployment/traefik --timeout=100s && \
   for i in $(seq 1 30); do wget -qO- http://127.0.0.1:8080/ > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://127.0.0.1:8080/
   ```
