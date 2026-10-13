# Ports and ingress

The nodes are containers on a Docker network of their own.
The only way from the machine into the cluster that works the same on every system is a port published by Docker, and k3d publishes them on the load balancer.

## Publish a port

A mapping reads `<host port>:<container port>@<node filter>`, and the filter `loadbalancer` names the `k3d-proxy` container.
Ports are chosen when the cluster is created, and one can be added to a running cluster further down.

1. Create a cluster that maps the port 8080 of the machine to the port 80 of the servers.
   Traefik, the ingress controller of k3s, listens on that port:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create dev --image "${NODE_IMAGE}" --port "8080:80@loadbalancer"
   ```

2. The container publishes the port, and nginx forwards it to the server node, by its name on the Docker network.
   The load balancer sends a mapped port to the server nodes only:

   <!-- verify: expect="80/tcp -> 0.0.0.0:8080" -->

   ```bash exec target=docker
   docker port k3d-dev-serverlb
   ```

   <!-- verify: expect="dev-server-0:80" -->

   ```bash exec target=docker
   docker exec k3d-dev-serverlb grep -E "listen|server k3d" /etc/nginx/nginx.conf
   ```

## Route to an application

1. Deploy a web server, a Service in front of it, and an Ingress that sends every path to the Service:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=docker
   mkdir -p ~/lab/networking && cd ~/lab/networking && \
   tee web.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         labels:
           app: web
       spec:
         containers:
           - name: web
             image: ${NGINX_IMAGE}
             ports:
               - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: web
   spec:
     selector:
       app: web
     ports:
       - port: 80
   ---
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: web
   spec:
     rules:
       - http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: web
                   port:
                     number: 80
   EOT
   kubectl apply -f web.yaml && \
   kubectl rollout status deployment/web --timeout=200s
   ```

2. Request the page on the port of the machine.
   The request goes through Docker, the load balancer, the node, Traefik and the Service, and the loop waits for Traefik to start:

   <!-- verify: timeout=120 expect="Welcome to nginx" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do wget -qO- http://127.0.0.1:8080/ > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://127.0.0.1:8080/ | grep "<title>"
   ```

   On a workstation, the address is `http://localhost:8080/` in a browser, on Linux, macOS and Windows alike.

## Services of type LoadBalancer

k3s answers a Service of type `LoadBalancer` with ServiceLB: a Pod per node that uses the port of the Service on the node.
The k3s documentation says a port can serve one Service on a node, and that Traefik uses 80 and 443, so another Service takes another port.

1. Expose the Deployment on the port 8000:

   <!-- verify: timeout=120 expect="8000:" -->

   ```bash exec target=docker
   kubectl expose deployment web --name web-lb --port 8000 --target-port 80 --type LoadBalancer && \
   for i in $(seq 1 60); do kubectl get service web-lb --no-headers | grep -qv "<pending>" && break; sleep 2; done; \
   kubectl get service web-lb
   ```

   The external address is the one of the node container on the Docker network.

2. On Linux, that address answers from the machine, because the Docker network is a bridge of the host.
   On Docker Desktop, the page about its networking says that the `bridge` network is not reachable from the host, so the same request would fail there:

   <!-- verify: expect="Welcome to nginx" -->

   ```bash exec target=docker
   wget -qO- "http://$(kubectl get service web-lb --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8000/" | grep "<title>"
   ```

3. The portable way is the one of the first section, a port of the load balancer.
   `cluster edit` adds one to the running cluster, by replacing the `k3d-proxy` container with a new one:

   <!-- verify: expect="Successfully updated" -->

   ```bash exec target=docker
   k3d cluster edit dev --port-add "8081:8000@loadbalancer"
   ```

   <!-- verify: timeout=60 expect="Welcome to nginx" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do wget -qO- http://127.0.0.1:8081/ > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://127.0.0.1:8081/ | grep "<title>"
   ```

## From the cluster to the machine

A Pod sometimes needs a service that runs on the developer's machine, a database or an API under development.
k3d adds the name `host.k3d.internal` to the DNS of the cluster, with the address of the gateway of the Docker network, which is the machine.

1. Start a web server on the machine, on all its addresses:

   ```bash exec target=docker
   mkdir -p ~/lab/networking/site && cd ~/lab/networking/site && \
   echo "served by the machine" > index.html
   nohup python3 -m http.server 9000 > ~/lab/networking/site.log 2>&1 &
   ```

2. Start a Pod that waits, and call the server from it.
   CoreDNS reloads its records every 15 seconds, so the call waits until the name resolves:

   <!-- verify: requires=network timeout=240 expect="served by the machine" -->

   ```bash exec target=docker
   kubectl run caller --image "${BUSYBOX_IMAGE}" --restart Never --command -- sleep 3600 && \
   kubectl wait --for condition=Ready pod/caller --timeout 200s && \
   until kubectl exec caller -- nslookup host.k3d.internal. > /dev/null 2>&1; do sleep 3; done; \
   kubectl exec caller -- wget -qO- http://host.k3d.internal:9000/
   ```

3. Stop the server and delete the cluster:

   <!-- verify: expect="Successfully deleted cluster" -->

   ```bash exec target=docker
   pkill -f "^python3 -m http.server 9000"; \
   k3d cluster delete dev
   ```
