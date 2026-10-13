# Certificates

A certificate by hand expires, and each host needs one.
cert-manager does it from the cluster: it asks an issuer for a certificate, stores it in the Secret the Ingress names, and renews it before it expires.

## Install cert-manager

cert-manager is a set of controllers and custom resources, published as one manifest per release.
`--server-side` is what its installation page asks for with such large resources.

1. Apply the manifest of the release, and wait for its three Deployments:

   <!-- verify: requires=network timeout=300 expect="condition met" -->

   ```bash exec target=docker
   kubectl apply --server-side -f "${CERTMANAGER_URL}/${CERTMANAGER_VERSION}/cert-manager.yaml" > /dev/null && \
   kubectl --namespace cert-manager wait --for condition=Available deployment --all --timeout 240s
   ```

   <!-- verify: expect="cert-manager-webhook" -->

   ```bash exec target=docker
   kubectl --namespace cert-manager get deployments
   ```

## An issuer

An `Issuer` or a `ClusterIssuer` says how certificates are obtained.
The lab has no domain and no access to a public authority, so it builds a small one:
a self-signed issuer signs the certificate of an authority of the lab (`isCA: true`), and a second issuer signs with that authority.
That is a private PKI, the same shape a company uses for its internal names.

1. Create the three resources:

   <!-- verify: expect="READY" -->

   ```bash exec target=docker
   mkdir -p ~/lab/certs && cd ~/lab/certs && \
   tee issuers.yaml <<EOT
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: selfsigned
   spec:
     selfSigned: {}
   ---
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: lab-ca
     namespace: cert-manager
   spec:
     isCA: true
     commonName: lab-ca
     secretName: lab-ca
     privateKey:
       algorithm: ECDSA
       size: 256
     issuerRef:
       name: selfsigned
       kind: ClusterIssuer
   ---
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: lab-ca
   spec:
     ca:
       secretName: lab-ca
   EOT
   for i in $(seq 1 30); do kubectl apply -f issuers.yaml > /dev/null 2>&1 && break; sleep 2; done; \
   kubectl get clusterissuer
   ```

2. Wait until the authority is ready:

   <!-- verify: timeout=120 expect="clusterissuer.cert-manager.io/lab-ca condition met" -->

   ```bash exec target=docker
   kubectl wait --for condition=Ready clusterissuer/lab-ca --timeout 100s
   ```

## A certificate from an Ingress

The annotation `cert-manager.io/cluster-issuer` on an Ingress is enough: cert-manager creates a `Certificate` from its `tls` section, with the hosts as names and the Secret as target.

1. Create an Ingress for a new host, with the annotation:

   <!-- verify: expect="ingress.networking.k8s.io/auto created" -->

   ```bash exec target=docker
   cd ~/lab/certs && \
   tee auto.yaml <<EOT
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: auto
     annotations:
       cert-manager.io/cluster-issuer: lab-ca
   spec:
     ingressClassName: traefik
     tls:
       - hosts:
           - auto.example.test
         secretName: auto-tls
     rules:
       - host: auto.example.test
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
   kubectl apply -f auto.yaml
   ```

2. cert-manager created the `Certificate`, ordered the certificate from the issuer, and wrote the Secret:

   <!-- verify: timeout=120 expect="certificate.cert-manager.io/auto-tls condition met" -->

   ```bash exec target=docker
   kubectl wait --for condition=Ready certificate/auto-tls --timeout 100s && \
   kubectl get certificate,secret auto-tls
   ```

3. The certificate is served, signed by the authority of the lab, and renews before its end: it lasts 90 days, and renewal is planned 30 days before the end.
   The authority itself is in the Secret, as `ca.crt`:

   <!-- verify: timeout=60 expect="issuer=CN = lab-ca" -->

   ```bash exec target=docker
   cd ~/lab/certs && \
   for i in $(seq 1 30); do openssl s_client -connect 127.0.0.1:8443 -servername auto.example.test < /dev/null 2> /dev/null | openssl x509 -noout -issuer | grep -q lab-ca && break; sleep 2; done; \
   openssl s_client -connect 127.0.0.1:8443 -servername auto.example.test < /dev/null 2> /dev/null | openssl x509 -noout -subject -issuer -dates
   ```

   <!-- verify: expect="renewal at: 20" -->

   ```bash exec target=docker
   echo "renewal at: $(kubectl get certificate auto-tls --output jsonpath='{.status.renewalTime}')"
   ```

4. A client that trusts the authority trusts every certificate it signs, with no file per host:

   <!-- verify: expect="Name: blog" -->

   ```bash exec target=docker
   cd ~/lab/certs && \
   kubectl get secret auto-tls --output jsonpath='{.data.ca\.crt}' | base64 -d > lab-ca.crt && \
   wget -qO- --ca-certificate lab-ca.crt https://auto.example.test:8443/ | grep "^Name"
   ```
