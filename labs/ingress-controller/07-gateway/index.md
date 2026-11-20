# Gateway API

The Kubernetes documentation says the Ingress API is frozen, and recommends the Gateway API instead.
It splits what the Ingress mixed into resources with an owner each, and carries in its standard what annotations did.

Resource       | Owner                | Says
---------------|----------------------|---------------------------------------------------------------------
`GatewayClass` | The platform         | Which controller implements the gateways of this class
`Gateway`      | The cluster operator | Which ports, protocols, names and certificates are open
`HTTPRoute`    | The application team | Which hosts and paths go to which Services, with filters and weights

## The definitions

The resources of the Gateway API are custom resources, not part of Kubernetes itself: a cluster needs their definitions (CRDs), from the release of the project.
The standard channel holds the ones that are generally available or beta, among them `GatewayClass`, `Gateway`, `HTTPRoute` and `ReferenceGrant`.
k3s installs them with Traefik, so this cluster has them already.
On another cluster, the release publishes a `standard-install.yaml` to apply.

1. Read the version of the definitions, and what owns them:

   <!-- verify: expect="Gateway API: v1" -->

   ```bash exec target=docker
   echo "Gateway API: $(kubectl get crd httproutes.gateway.networking.k8s.io --output jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}')" && \
   kubectl get crd --output name | grep gateway.networking.k8s.io
   ```

2. Traefik implements the Gateway API when its provider is enabled.
   k3s installs Traefik with a Helm chart, and a `HelmChartConfig` of the same name changes the values of the chart:

   <!-- verify: expect="helmchartconfig.helm.cattle.io/traefik created" -->

   ```bash exec target=docker
   mkdir -p ~/lab/gateway && cd ~/lab/gateway && \
   tee traefik-config.yaml <<EOT
   apiVersion: helm.cattle.io/v1
   kind: HelmChartConfig
   metadata:
     name: traefik
     namespace: kube-system
   spec:
     valuesContent: |-
       providers:
         kubernetesGateway:
           enabled: true
   EOT
   kubectl apply -f traefik-config.yaml
   ```

3. Wait for the class, which the chart creates, to be accepted by the controller:

   <!-- verify: timeout=240 expect="traefik.io/gateway-controller" -->

   ```bash exec target=docker
   for i in $(seq 1 100); do kubectl get gatewayclass traefik > /dev/null 2>&1 && break; sleep 3; done; \
   for i in $(seq 1 40); do kubectl get gatewayclass traefik --no-headers 2> /dev/null | grep -q True && break; sleep 3; done; \
   kubectl get gatewayclass
   ```

## A gateway and a route

1. The gateway opens the port of the entry point `web` of Traefik, 8000 in the Pod (the Service maps it to 80).
   A listener port must match an entry point of the controller.
   Routes of the same namespace may attach:

   <!-- verify: expect="gateway.gateway.networking.k8s.io/lab created" -->

   ```bash exec target=docker
   cd ~/lab/gateway && \
   kubectl delete ingress --all && \
   tee gateway.yaml <<EOT
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: lab
   spec:
     gatewayClassName: traefik
     listeners:
       - name: http
         protocol: HTTP
         port: 8000
         allowedRoutes:
           namespaces:
             from: Same
   EOT
   kubectl apply -f gateway.yaml
   ```

2. The route holds the rules.
   Two Services share the traffic by weight, a feature the Ingress could only get from annotations:

   <!-- verify: expect="httproute.gateway.networking.k8s.io/app created" -->

   ```bash exec target=docker
   cd ~/lab/gateway && \
   tee route.yaml <<EOT
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: app
   spec:
     parentRefs:
       - name: lab
     hostnames:
       - gateway.example.test
     rules:
       - backendRefs:
           - name: shop
             port: 80
             weight: 50
           - name: blog
             port: 80
             weight: 50
   EOT
   kubectl apply -f route.yaml
   ```

3. The status says whether the gateway and the route were accepted:

   <!-- verify: timeout=120 expect="PROGRAMMED" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do kubectl get httproute app --output jsonpath='{.status.parents[0].conditions[*].type}' | grep -q Accepted && break; sleep 2; done; \
   kubectl get gateway lab && \
   kubectl get httproute app --output jsonpath='{.status.parents[0].conditions[*].type}{"\n"}'
   ```

4. Thirty requests reach both applications:

   <!-- verify: timeout=60 expect="applications reached: 2" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do wget -qO- http://gateway.example.test:8080/ > /dev/null 2>&1 && break; sleep 2; done; \
   echo "applications reached: $(for i in $(seq 1 30); do wget -qO- http://gateway.example.test:8080/ | grep '^Name'; done | sort -u | wc -l)"
   ```

## HTTPS and filters

The listener is where TLS ends, and the Secret is named by `certificateRefs`, in the same namespace: the Secret `auto-tls` that cert-manager made in the previous step is reused.
What needed a Traefik annotation and a middleware with the Ingress are standard filters of the route: `URLRewrite` removes a prefix, `RequestRedirect` sends the client to HTTPS.

1. Add an HTTPS listener to the gateway.
   Its port, 8443, is the one of the entry point `websecure` of Traefik in the Pod:

   <!-- verify: expect="gateway.gateway.networking.k8s.io/lab configured" -->

   ```bash exec target=docker
   cd ~/lab/gateway && \
   tee gateway.yaml <<EOT
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: lab
   spec:
     gatewayClassName: traefik
     listeners:
       - name: http
         protocol: HTTP
         port: 8000
         allowedRoutes:
           namespaces:
             from: Same
       - name: https
         protocol: HTTPS
         port: 8443
         hostname: auto.example.test
         tls:
           mode: Terminate
           certificateRefs:
             - kind: Secret
               name: auto-tls
         allowedRoutes:
           namespaces:
             from: Same
   EOT
   kubectl apply -f gateway.yaml
   ```

2. Two routes: one attached to the HTTPS listener, which sends `/shop` and `/blog` to their Service with the prefix removed, and one attached to the HTTP listener, which redirects:

   <!-- verify: expect="httproute.gateway.networking.k8s.io/redirect created" -->

   ```bash exec target=docker
   cd ~/lab/gateway && \
   tee secure.yaml <<EOT
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: secure
   spec:
     parentRefs:
       - name: lab
         sectionName: https
     hostnames:
       - auto.example.test
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /shop
         filters:
           - type: URLRewrite
             urlRewrite:
               path:
                 type: ReplacePrefixMatch
                 replacePrefixMatch: /
         backendRefs:
           - name: shop
             port: 80
       - matches:
           - path:
               type: PathPrefix
               value: /blog
         filters:
           - type: URLRewrite
             urlRewrite:
               path:
                 type: ReplacePrefixMatch
                 replacePrefixMatch: /
         backendRefs:
           - name: blog
             port: 80
   ---
   apiVersion: gateway.networking.k8s.io/v1
   kind: HTTPRoute
   metadata:
     name: redirect
   spec:
     parentRefs:
       - name: lab
         sectionName: http
     hostnames:
       - auto.example.test
     rules:
       - filters:
           - type: RequestRedirect
             requestRedirect:
               scheme: https
               port: 8443
               statusCode: 301
   EOT
   kubectl apply -f secure.yaml
   ```

3. The HTTPS request goes through with the certificate of cert-manager, and the application receives the path without its prefix:

   <!-- verify: timeout=90 expect="GET /items HTTP/1.1" -->

   ```bash exec target=docker
   cd ~/lab/certs && \
   for i in $(seq 1 30); do wget -qO- --ca-certificate lab-ca.crt https://auto.example.test:8443/shop/items > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- --ca-certificate lab-ca.crt https://auto.example.test:8443/shop/items | grep -E "^(Name|GET)"
   ```

4. The HTTP request is redirected:

   <!-- verify: timeout=60 expect="Location: https://auto.example.test:8443/" -->

   ```bash exec target=docker
   for i in $(seq 1 15); do wget --max-redirect 0 -S -O /dev/null http://auto.example.test:8080/ 2>&1 | grep -q "301" && break; sleep 2; done; \
   wget --max-redirect 0 -S -O /dev/null http://auto.example.test:8080/ 2>&1 | grep -iE "HTTP/1.1|Location"
   ```
