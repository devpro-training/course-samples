# Routing

One address, many applications: the controller chooses the Service from the host and the path of the request.
The cluster and the `shop` application of the previous step stay.

## Names

A browser sends the name it was given in the `Host` header, and the controller routes on it.
The names of this lab end in `.test`, a top-level domain reserved for tests (RFC 2606), so they never exist in the DNS.
On a workstation, the `hosts` file maps them to `127.0.0.1`, which is what the machine of this lab gets:

1. Map the names of the lab to the machine:

   <!-- verify: expect="names mapped: 2" -->

   ```bash exec target=docker
   echo "127.0.0.1 shop.example.test blog.example.test app.example.test auto.example.test gateway.example.test" >> /etc/hosts && \
   echo "names mapped: $(getent hosts shop.example.test blog.example.test | wc -l)"
   ```

2. Deploy a second application, `blog`, and remove the Ingress of the previous step:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=docker
   mkdir -p ~/lab/routing && cd ~/lab/routing && \
   tee blog.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: blog
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: blog
     template:
       metadata:
         labels:
           app: blog
       spec:
         containers:
           - name: blog
             image: ${WHOAMI_IMAGE}
             env:
               - name: WHOAMI_NAME
                 value: blog
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: blog
   spec:
     selector:
       app: blog
     ports:
       - port: 80
   EOT
   kubectl apply -f blog.yaml && \
   kubectl delete ingress shop && \
   kubectl rollout status deployment/blog --timeout=200s
   ```

## By host

1. One Ingress, one rule per host.
   `ingressClassName` names the class of the controller: Traefik is the default class of the cluster, and the Kubernetes documentation recommends naming it all the same:

   <!-- verify: expect="ingress.networking.k8s.io/hosts created" -->

   ```bash exec target=docker
   cd ~/lab/routing && \
   tee hosts.yaml <<EOT
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: hosts
   spec:
     ingressClassName: traefik
     rules:
       - host: shop.example.test
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: shop
                   port:
                     number: 80
       - host: blog.example.test
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: blog
                   port:
                     number: 80
   EOT
   kubectl apply -f hosts.yaml
   ```

2. The same address and the same port answer with the application of the name:

   <!-- verify: timeout=60 expect="Name: blog" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do wget -qO- http://blog.example.test:8080/ > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://shop.example.test:8080/ | grep "^Name" && \
   wget -qO- http://blog.example.test:8080/ | grep "^Name"
   ```

3. A name that no rule has is answered by the controller itself.
   `wget` hides the body of an error unless it is asked to keep it:

   <!-- verify: expect="404 page not found" -->

   ```bash exec target=docker
   { wget -qO- --content-on-error http://app.example.test:8080/ || true; }
   ```

## By path

1. One host, a path per application.
   A `Prefix` path matches by path element: `/shop` matches `/shop` and `/shop/items`, and not `/shopping`.
   When two paths match, the longest wins:

   <!-- verify: expect="ingress.networking.k8s.io/paths created" -->

   ```bash exec target=docker
   cd ~/lab/routing && \
   kubectl delete ingress hosts && \
   tee paths.yaml <<EOT
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: paths
   spec:
     ingressClassName: traefik
     rules:
       - host: app.example.test
         http:
           paths:
             - path: /shop
               pathType: Prefix
               backend:
                 service:
                   name: shop
                   port:
                     number: 80
             - path: /blog
               pathType: Prefix
               backend:
                 service:
                   name: blog
                   port:
                     number: 80
   EOT
   kubectl apply -f paths.yaml
   ```

2. The application receives the whole path, including the prefix it knows nothing about.
   The line `GET` of `whoami` shows it:

   <!-- verify: timeout=60 expect="GET /shop/items HTTP/1.1" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do wget -qO- http://app.example.test:8080/blog > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://app.example.test:8080/shop/items | grep -E "^(Name|GET)"
   ```

## What the Ingress cannot say

Removing a prefix, redirecting, limiting, rewriting a header: the Ingress API has no field for them.
Each controller invented its own, as annotations on the Ingress, and an annotation is understood by one controller only.
Traefik reads the annotation `traefik.ingress.kubernetes.io/router.middlewares`, which names a `Middleware`, a custom resource of Traefik, as `<namespace>-<name>@kubernetescrd`.

1. Define a middleware that removes `/shop`, and use it on the Ingress:

   <!-- verify: expect="ingress.networking.k8s.io/paths annotated" -->

   ```bash exec target=docker
   cd ~/lab/routing && \
   tee strip.yaml <<EOT
   apiVersion: traefik.io/v1alpha1
   kind: Middleware
   metadata:
     name: strip-shop
   spec:
     stripPrefix:
       prefixes:
         - /shop
   EOT
   kubectl apply -f strip.yaml && \
   kubectl annotate ingress paths --overwrite traefik.ingress.kubernetes.io/router.middlewares=default-strip-shop@kubernetescrd
   ```

2. The application now receives `/items`.
   Moving this Ingress to another controller would lose the annotation, and so the behavior:

   <!-- verify: timeout=60 expect="GET /items HTTP/1.1" -->

   ```bash exec target=docker
   for i in $(seq 1 15); do wget -qO- http://app.example.test:8080/shop/items | grep -q "GET /items" && break; sleep 2; done; \
   wget -qO- http://app.example.test:8080/shop/items | grep -E "^(Name|GET)"
   ```

## Load balancing

The controller does not go through the Service address: it watches the endpoints of the Service, and balances between the Pods itself.

1. Scale `shop` to three replicas, and count the Pods that answer nine requests:

   <!-- verify: timeout=120 expect="answering Pods: 3" -->

   ```bash exec target=docker
   kubectl scale deployment shop --replicas 3 && \
   kubectl rollout status deployment/shop --timeout=100s && \
   sleep 5; \
   echo "answering Pods: $(for i in $(seq 1 9); do wget -qO- http://app.example.test:8080/shop/ | grep "^Hostname"; done | sort -u | wc -l)"
   ```
