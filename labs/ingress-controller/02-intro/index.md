# Ingress controller

How HTTP gets into a Kubernetes cluster, and how HTTPS is handled once there.

---

## The problem

- **A Pod has an address nobody should depend on**: it changes with every restart, and only the cluster can reach it.

- **A Service gives a stable name and address**, and its default type, `ClusterIP`, is reachable from inside the cluster only.

- **By default, nothing is reachable from outside**: an application running in the cluster has no way to be called by a browser.

Service type  | What it gives                            | Limit
--------------|------------------------------------------|-----------------------------------------------------------
`ClusterIP`    | A stable address inside the cluster      | Inside only
`NodePort`     | The same port, 30000 to 32767, on each node | A port per Service, at the address of a node
`LoadBalancer` | An external address from the platform    | An address per Service, with no names, no paths, no certificate

- A web site is more than a port: names, paths, one certificate per name, one entry for the whole cluster.

---

## How it works

![A client reaches an ingress controller, which reads Ingress and route resources from the cluster, takes certificates from Secrets issued by cert-manager, and sends HTTP to the Services](../assets/ingress-dark.svg#gh-dark-mode-only)
![A client reaches an ingress controller, which reads Ingress and route resources from the cluster, takes certificates from Secrets issued by cert-manager, and sends HTTP to the Services](../assets/ingress.svg#gh-light-mode-only)

---

## Ingress and controller

- **An Ingress is data**: the documentation says it exposes HTTP and HTTPS routes from outside the cluster to Services, and that "only creating an Ingress resource has no effect".

- **The controller does the work**: a reverse proxy in the cluster that watches the Ingress resources, and configures itself from them, "usually with a load balancer".

- **The class links them**: `ingressClassName` names an `IngressClass`, which names a controller.
  A class marked as the default serves the Ingresses that name none.

- **Controllers differ**: "the various Ingress controllers operate slightly differently", so a controller's documentation is part of the job.

- **One entry for the cluster**: the controller itself is reached by a `LoadBalancer` or a published port, once, and every application goes through it.

- Reference: [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).

---

## Rules

Rule                 | Meaning
---------------------|--------------------------------------------------------------------------------------
`host`               | An exact name, or a wildcard such as `*.foo.com` which covers one label only
`path` and `Prefix`  | Matches by path element, case sensitive: `/shop` matches `/shop/items`, not `/shopping`
`path` and `Exact`   | The path exactly, case sensitive
`ImplementationSpecific` | Left to the class
Several matches      | The longest path wins, then `Exact` over `Prefix`
No match             | The default backend, or what the controller decides: Traefik answers `404 page not found`

- Everything else, removing a prefix, redirecting, limiting, rewriting, is **annotations**, understood by one controller only.

---

## HTTPS

- **TLS ends at the controller**: it holds the certificates, and the Service and the Pods receive plain HTTP.

- **A Secret holds the certificate**: type `kubernetes.io/tls`, with the keys `tls.crt` and `tls.key`, named in the `tls` section of the Ingress.

- **The hosts of `tls` match the hosts of the rules**, since a certificate is issued for names.

- **One address, many certificates**: the client sends the name it wants in the handshake (SNI), and the controller picks the certificate.
  A name with no certificate gets the default one of the controller, which no client trusts.

- **A certificate is signed by an authority** the client already trusts: a public one (Let's Encrypt) for the internet, a private one for internal names.

- **A certificate expires**, so a person who renews it by hand will forget one day: this is the job of **cert-manager**.

---

## cert-manager

- **A controller and custom resources** that obtain certificates from an `Issuer` or a `ClusterIssuer`, store them in a Secret, and renew them.

- **The annotation `cert-manager.io/cluster-issuer`** on an Ingress is enough: cert-manager creates the `Certificate` from its `tls` section.

Issuer     | Use
-----------|--------------------------------------------------------------------------------------------
`selfSigned` | "Generally useful for bootstrapping a PKI locally": the lab signs the certificate of its own authority with it
`ca`       | Signs with an authority held in a Secret: a private PKI for internal names, which clients must trust
`acme`     | An ACME authority such as Let's Encrypt, which checks the name with a challenge

- **ACME, HTTP-01**: the authority requests a key at a URL of the domain, so the name must be routable from the internet, and cert-manager routes that URL through the Ingress.

- **ACME, DNS-01**: the key is a TXT record, created with the credentials of the DNS provider.
  It needs no inbound access, and it is the only challenge for a wildcard certificate.

- **Test with the staging endpoint** of the authority first: its URL is `https://acme-staging-v02.api.letsencrypt.org/directory` in the documentation of cert-manager.

- References: [Ingress annotations](https://cert-manager.io/docs/usage/ingress/), [ACME](https://cert-manager.io/docs/configuration/acme/), [self-signed](https://cert-manager.io/docs/configuration/selfsigned/).

---

## Controllers

- **Traefik is in k3s**: k3s ships Traefik v3, with its Service on the ports 80 and 443, and a `HelmChartConfig` changes its values.
  `--disable=traefik` removes it, for another controller.

- **The Kubernetes documentation lists** about thirty, among them the NGINX Ingress Controller of nginx.com, HAProxy, Contour, Kong, Cilium, Istio, Traefik and APISIX, and says it is not responsible for these third-party projects.
  It supports and maintains the controllers of AWS and of GCE.

- **ingress-nginx is retired**: the Kubernetes project announced on 11 November 2025 that best-effort maintenance would stop in March 2026, with no more releases, bug fixes or security updates after it.
  Existing deployments keep working, and the installation artifacts stay available.
  The project advised moving to the Gateway API, or to another controller, and its January 2026 statement says none is a drop-in replacement.

- **A controller is a dependency to choose**: its maintenance, its annotations and its security updates are what the team depends on.

- References: [controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/), 
  [retirement of ingress-nginx](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), [k3s networking](https://docs.k3s.io/networking/networking-services).

---

## Gateway API

- **The Ingress API is frozen**: the documentation says it is generally available with no plan to remove it, that it "will have no further changes or updates", and that the project recommends the Gateway API instead.

- **Roles in separate resources**: a `GatewayClass` for the platform, a `Gateway` for the operator (ports, protocols, names, certificates), and routes such as `HTTPRoute` for the application teams.

- **The standard carries what annotations did**: weights between Services, path matches, URL rewrites, redirects, and TLS on the listener (`certificateRefs`), the same in every implementation that supports them.

- **Beyond HTTP**: `GRPCRoute` is generally available in the standard channel, and `TCPRoute` and `UDPRoute` are in the experimental one.

- **The definitions are separate from Kubernetes**: a cluster needs the CRDs of a release, which k3s installs with Traefik (v1.6.1 in the lab).

- **cert-manager supports it**: the same annotations on a `Gateway`, for each listener with a hostname and a `Terminate` mode, once `config.gatewayAPI.enabled` is set.

- References: [Gateway API](https://gateway-api.sigs.k8s.io/), 
  [Traefik provider](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/gateway-api/), [cert-manager and Gateways](https://cert-manager.io/docs/usage/gateway/).

---

## A cluster on a laptop is not on the internet

- **A development cluster has no public address**: it sits behind a router, and a webhook, a demonstration or a certificate challenge cannot reach it.

- **A tunnel connects out instead of waiting for connections in**: no open port and no public IP.

Tool         | In its own words
-------------|---------------------------------------------------------------------------------------------------------
cloudflared  | Cloudflare Tunnel: a daemon that opens outbound connections to the network of Cloudflare, so inbound traffic can be blocked
ngrok        | The ngrok Kubernetes Operator exposes services "through standard Kubernetes resources", "like Ingress or the Gateway API"

- Both run in the cluster: `cloudflared` as a Deployment with the token of a tunnel created in Cloudflare, and the ngrok operator installed with Helm (its documentation links a Helm configuration reference).

- Neither is used in the lab, which has no account.

- They are a way to publish, not a replacement for the controller: the traffic still ends at an ingress controller or a gateway inside the cluster.

- **For a certificate of a cluster that is not routable from the internet**, the DNS-01 challenge works where HTTP-01 cannot.

- References: [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/), [ngrok Kubernetes Operator](https://ngrok.com/docs/k8s/).

---

## In this lab

Step             | What it shows
-----------------|----------------------------------------------------------------------------------------------
Setup            | Docker Engine, k3d and kubectl, from checked release binaries
Reach an application | ClusterIP, NodePort, then an Ingress, and a controller that is stopped
Routing          | Hosts, paths, a middleware for what the Ingress cannot say, balancing between Pods
HTTPS            | The default certificate, SNI, a Secret by hand, trust, a redirect to HTTPS
Certificates     | cert-manager, a private authority, a certificate from an annotation, renewal
Gateway API      | A `Gateway` and routes on Traefik, weights, filters, an HTTPS listener

> One virtual machine and no account: no public name is used, so the lab names end in `.test`, mapped to the machine, and the authority is its own.
