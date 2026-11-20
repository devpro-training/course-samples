# HTTPS

The controller is the one place where TLS ends: it holds the certificates, speaks HTTPS to the clients, and sends plain HTTP to the Services inside the cluster.
An Ingress names the Secret that holds the certificate of a host.
The Kubernetes documentation says that Secret must contain the keys `tls.crt` and `tls.key`, and that the hosts of the `tls` section must match the hosts of the rules.

## Without a certificate

1. Ask for the certificate the controller serves for a name it holds no certificate for.
   The name is sent in the handshake (SNI), which is how one address serves many certificates:

   <!-- verify: expect="TRAEFIK DEFAULT CERT" -->

   ```bash exec target=docker
   cd ~/lab && \
   openssl s_client -connect 127.0.0.1:8443 -servername shop.example.test < /dev/null 2> /dev/null | openssl x509 -noout -subject
   ```

   Traefik presents a certificate of its own, generated at start, which no client trusts.

## A certificate by hand

A certificate is a public key signed by an authority.
Here, the lab signs its own: `openssl` makes the key and a certificate valid for 30 days, with the name in the `subjectAltName` field, which is what clients check.

1. Create the key and the certificate:

   <!-- verify: expect="X509v3 Subject Alternative Name" -->

   ```bash exec target=docker
   mkdir -p ~/lab/https && cd ~/lab/https && \
   openssl req -x509 -newkey rsa:2048 -nodes -days 30 -keyout shop.key -out shop.crt \
     -subj "/CN=shop.example.test" -addext "subjectAltName=DNS:shop.example.test" 2> /dev/null && \
   openssl x509 -in shop.crt -noout -subject -issuer -ext subjectAltName
   ```

   The issuer is the subject: the certificate vouches for itself.

2. Store them in a Secret of the type `kubernetes.io/tls`:

   <!-- verify: expect="kubernetes.io/tls" -->

   ```bash exec target=docker
   cd ~/lab/https && \
   kubectl create secret tls shop-tls --cert shop.crt --key shop.key && \
   kubectl get secret shop-tls
   ```

3. Remove the Ingress of the previous step, and create one with a `tls` section.
   Traefik names its ports entry points, `web` for HTTP and `websecure` for HTTPS, and an annotation limits the Ingress to the second: without it, the same rule also answers in plain HTTP, which the redirect below must take over:

   <!-- verify: expect="ingress.networking.k8s.io/shop created" -->

   ```bash exec target=docker
   cd ~/lab/https && \
   kubectl delete ingress paths && \
   tee shop.yaml <<EOT
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: shop
     annotations:
       traefik.ingress.kubernetes.io/router.entrypoints: websecure
   spec:
     ingressClassName: traefik
     tls:
       - hosts:
           - shop.example.test
         secretName: shop-tls
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
   EOT
   kubectl apply -f shop.yaml
   ```

4. The controller now serves that certificate for that name:

   <!-- verify: timeout=60 expect="CN = shop.example.test" -->

   ```bash exec target=docker
   cd ~/lab/https && \
   for i in $(seq 1 30); do openssl s_client -connect 127.0.0.1:8443 -servername shop.example.test < /dev/null 2> /dev/null | openssl x509 -noout -subject | grep -q shop && break; sleep 2; done; \
   openssl s_client -connect 127.0.0.1:8443 -servername shop.example.test < /dev/null 2> /dev/null | openssl x509 -noout -subject
   ```

## Trust

A client trusts a certificate when it is signed by an authority it already knows.
The lab's certificate is signed by nobody, so a client refuses it, until it is given the certificate as the authority:

1. Without the authority, the request fails and `wget` says why:

   <!-- verify: timeout=60 expect="status 5" -->

   ```bash exec target=docker
   wget -qO- --tries 1 https://shop.example.test:8443/; \
   echo "status $?"
   ```

2. With the certificate as the authority, the request goes through, and the application sees plain HTTP:

   <!-- verify: expect="X-Forwarded-Proto: https" -->

   ```bash exec target=docker
   cd ~/lab/https && \
   wget -qO- --ca-certificate shop.crt https://shop.example.test:8443/ | grep -E "^(Name|X-Forwarded-Proto)"
   ```

   Switching the verification off (`--no-check-certificate`, `curl -k`) makes it work too, and removes what HTTPS is for.

## From HTTP to HTTPS

A client that arrives on the port 80 must be sent to the port 443.
The Ingress API has no field for it, so Traefik does it with a middleware, `redirectScheme`, attached to a second Ingress that only listens on the HTTP entry point.
The lab publishes HTTPS on 8443, so the redirect names that port.

1. Create the middleware, and the Ingress that redirects:

   <!-- verify: expect="ingress.networking.k8s.io/shop-redirect created" -->

   ```bash exec target=docker
   cd ~/lab/https && \
   tee redirect.yaml <<EOT
   apiVersion: traefik.io/v1alpha1
   kind: Middleware
   metadata:
     name: to-https
   spec:
     redirectScheme:
       scheme: https
       port: "8443"
       permanent: true
   ---
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: shop-redirect
     annotations:
       traefik.ingress.kubernetes.io/router.entrypoints: web
       traefik.ingress.kubernetes.io/router.middlewares: default-to-https@kubernetescrd
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
   EOT
   kubectl apply -f redirect.yaml
   ```

2. Request the HTTP address without following the redirect:

   <!-- verify: timeout=60 expect="Location: https://shop.example.test:8443/" -->

   ```bash exec target=docker
   for i in $(seq 1 15); do wget --max-redirect 0 -S -O /dev/null http://shop.example.test:8080/ 2>&1 | grep -q "301" && break; sleep 2; done; \
   wget --max-redirect 0 -S -O /dev/null http://shop.example.test:8080/ 2>&1 | grep -iE "HTTP/1.1|Location"
   ```
