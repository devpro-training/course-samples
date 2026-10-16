# Install Rancher

Rancher is a Helm chart installed in a Kubernetes cluster, which then becomes its `local` cluster.
The documentation installs it on k3s or RKE2, and in production on three nodes, with nothing else on them.

## The name

Rancher is reached by one name, its hostname, which the browser and every managed cluster use.
The lab uses the name of this machine, `docker`, which the browser of the lab and the machine `kube` both resolve.

1. Make sure the machine resolves its own name too:

   <!-- verify: expect="resolves: 1" -->

   ```bash exec target=docker
   getent hosts "${UI_HOST}" > /dev/null || echo "127.0.0.1 ${UI_HOST}" >> /etc/hosts; \
   echo "resolves: $(getent hosts "${UI_HOST}" | wc -l)"
   ```

## The local cluster

1. Create a cluster of one node.
   The port 443 of the machine goes to the ingress controller of k3s, Traefik, which serves the hostname of Rancher:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create rancher --image "${NODE_IMAGE}" --port "443:443@loadbalancer"
   ```

2. Wait until the node is ready:

   <!-- verify: timeout=120 expect="ready nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "ready nodes: $(kubectl get nodes | grep -c ' Ready')"
   ```

## cert-manager

Rancher only answers over TLS.
By default its chart asks [cert-manager](https://cert-manager.io/) for the certificate, signed by a certificate authority that Rancher generates.
The other choices are Let's Encrypt (`ingress.tls.source=letsEncrypt`), a certificate of the company (`secret`), or TLS ended in front of Rancher (`tls=external`).

1. Install cert-manager with the manifest of one release:

   <!-- verify: requires=network timeout=300 expect="condition met" -->

   ```bash exec target=docker
   kubectl apply --server-side -f "${CERTMANAGER_URL}/${CERTMANAGER_VERSION}/cert-manager.yaml" > /dev/null && \
   kubectl --namespace cert-manager wait --for condition=Available deployment --all --timeout 240s
   ```

## The chart

1. Read what the chart creates before installing it.
   Rancher manages the cluster it runs in, so its service account is bound to `cluster-admin`:

   <!-- verify: requires=network timeout=120 expect="cluster-admin" -->

   ```bash exec target=docker
   helm template rancher rancher --repo "${RANCHERCHART_URL}" --version "${RANCHERCHART_VERSION}" --kube-version "${KUBECTL_VERSION}" \
     --namespace cattle-system --set hostname="${UI_HOST}" > ~/lab/rancher.yaml && \
   grep "^kind:" ~/lab/rancher.yaml | sort | uniq -c && \
   grep -A 3 "^roleRef:" ~/lab/rancher.yaml | grep "name:" | sort -u
   ```

2. Install it.
   `hostname` is required, `replicas=1` fits one node (the default is 3), and `bootstrapPassword` sets the first password of `admin`, which is random otherwise:

   <!-- verify: requires=network timeout=480 expect="successfully rolled out" -->

   ```bash exec target=docker
   helm install rancher rancher --repo "${RANCHERCHART_URL}" --version "${RANCHERCHART_VERSION}" \
     --namespace cattle-system --create-namespace \
     --set hostname="${UI_HOST}" --set replicas=1 --set bootstrapPassword="${UI_ADMIN_PASSWORD}" > /dev/null && \
   kubectl --namespace cattle-system rollout status deployment rancher --timeout=420s
   ```

3. The chart holds one Deployment.
   Rancher then installs the rest itself, as Helm releases of its own: its admission webhook, Fleet, and Rancher Turtles with the core of Cluster API.
   Wait until they are all there:

   <!-- verify: timeout=420 expect="cattle-turtles-system" -->

   ```bash exec target=docker
   for i in $(seq 1 100); do \
     [ "$(kubectl get deployments --all-namespaces --no-headers 2> /dev/null | grep -cE ' (rancher-webhook|fleet-controller|rancher-turtles-controller-manager|capi-controller-manager) +1/1 ')" = 4 ] && break; sleep 4; \
   done; \
   kubectl get deployments --all-namespaces | grep -E "^(NAMESPACE|cattle)"
   ```

4. `helm list` shows the releases Rancher installed, beside the one of this step and the Traefik of k3s:

   <!-- verify: expect="fleet-crd" -->

   ```bash exec target=docker
   helm list --all-namespaces --short
   ```

## The certificate

1. The authority that signs the certificate of Rancher is in the Secret `tls-rancher`, which a cert-manager `Issuer` uses.
   The certificate itself names the hostname and lasts 90 days:

   <!-- verify: expect="DNS:docker" -->

   ```bash exec target=docker
   kubectl --namespace cattle-system get secret tls-rancher -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/lab/ca.pem && \
   openssl x509 -in ~/lab/ca.pem -noout -subject -enddate && \
   kubectl --namespace cattle-system get secret tls-rancher-ingress -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -ext subjectAltName -enddate
   ```

2. With that authority, the machine trusts Rancher, with no `--no-check-certificate`:

   <!-- verify: requires=network expect="pong" -->

   ```bash exec target=docker
   wget -qO- --ca-certificate ~/lab/ca.pem "https://${UI_HOST}/ping"; echo
   ```

3. Rancher also serves the same authority at `/cacerts`, which is what an agent downloads, and checks against the checksum it was given:

   <!-- verify: expect="same authority: 1" -->

   ```bash exec target=docker
   echo "same authority: $( { sha256sum < ~/lab/ca.pem; wget -qO- --ca-certificate ~/lab/ca.pem "https://${UI_HOST}/cacerts" | sha256sum; } | sort -u | wc -l)"
   ```

## The server URL

Every cluster Rancher manages calls it back at one address, the setting `server-url`.
The first page of the interface asks for it, and an automated installation sets it as a resource, since every setting of Rancher is a Kubernetes object.

1. Set it, and read it back:

   <!-- verify: expect="https://docker" -->

   ```bash exec target=docker
   kubectl patch settings.management.cattle.io server-url --type merge --patch "{\"value\":\"https://${UI_HOST}\"}" > /dev/null && \
   kubectl get settings.management.cattle.io server-url -o jsonpath='{.value}{"\n"}'
   ```

## The interface

1. Open [Rancher](:navigate:rancher:https://docker/).
   Chrome stops at **Your connection is not private**: the authority of the certificate is the one of this Rancher, which the browser does not know.
   In production the certificate comes from the company or from Let's Encrypt, and the warning does not appear.
   Click **Advanced**, then **Proceed to docker (unsafe)**, or [let the link do it](:action:ui.proceed).

2. [Log in with the bootstrap password](:action:ui.login): the page asks for the password only, the user is `admin`.

3. The next page, **Welcome to Rancher!**, shows the **Server URL** set above, and the terms of the licence.
   [Accept them and continue](:action:ui.setup).
   The home page lists the clusters: one, `local`, the cluster Rancher runs in.
