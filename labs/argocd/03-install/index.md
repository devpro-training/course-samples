# Install Argo CD

Argo CD is installed in a cluster with the manifest of one release: a namespace, the definitions of its resources, and its parts.
That cluster is the hub, and it stays the one that runs Argo CD for the rest of the lab.

## The hub

1. Create the cluster.
   Traefik is disabled: nothing in this lab needs it, and the cluster starts faster and uses less memory.
   The port 8080 of the machine is mapped to the node port 30080 of the cluster, through the load balancer of k3d, which is where the web interface will be published:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create hub --image "${NODE_IMAGE}" --k3s-arg "--disable=traefik@server:*" --port "${UI_PORT}:${UI_NODE_PORT}@loadbalancer"
   ```

2. Wait until the node is ready:

   <!-- verify: timeout=120 expect="ready nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "ready nodes: $(kubectl get nodes | grep -c ' Ready')"
   ```

## The release

1. Install it.
   The manifest of the release is pinned by its tag, and applied server side, as the documentation says, since some definitions are too large for the annotation of a client side apply:

   <!-- verify: requires=network timeout=180 expect="argocd-server condition met" -->

   ```bash exec target=docker
   kubectl create namespace argocd && \
   kubectl apply --namespace argocd --server-side --force-conflicts \
     --filename "${ARGOCDREL_MANIFEST_URL}/${ARGOCDREL_VERSION}/manifests/install.yaml" > /dev/null && \
   kubectl --namespace argocd wait deployment --all --for=condition=Available --timeout=240s
   ```

2. The parts of the slides are Pods.
   The application controller is a StatefulSet, the others are Deployments:

   <!-- verify: timeout=120 expect="argocd-applicationset-controller" -->

   ```bash exec target=docker
   kubectl --namespace argocd rollout status statefulset argocd-application-controller --timeout=120s > /dev/null && \
   kubectl --namespace argocd get pods
   ```

3. The release also brings the resources that Argo CD is told things with:

   <!-- verify: expect="applicationsets.argoproj.io" -->

   ```bash exec target=docker
   kubectl get crd | grep "^[a-z]*\.argoproj\.io" | cut -d ' ' -f 1
   ```

## The web interface

The API server speaks TLS with a certificate of its own.
In a real installation an ingress ends TLS in front of it, and the server then speaks plain HTTP: this is what `server.insecure` asks for.
The lab has no ingress, and the browser panel would stop at a certificate warning, so the same setting is used.

1. Set it in the ConfigMap of the parameters, and restart the API server:

   <!-- verify: timeout=120 expect="successfully rolled out" -->

   ```bash exec target=docker
   kubectl --namespace argocd patch configmap argocd-cmd-params-cm --type merge --patch '{"data":{"server.insecure":"true"}}' > /dev/null && \
   kubectl --namespace argocd rollout restart deployment argocd-server > /dev/null && \
   kubectl --namespace argocd rollout status deployment argocd-server --timeout=120s
   ```

2. Publish the Service on the node port that the machine maps.
   A real installation puts an ingress in front of it, and `kubectl port-forward`, the way of the documentation, ends at the first connection that the server resets:

   <!-- verify: expect="service/argocd-server patched" -->

   ```bash exec target=docker
   kubectl --namespace argocd patch service argocd-server --type json \
     --patch "[{\"op\":\"replace\",\"path\":\"/spec/type\",\"value\":\"NodePort\"},{\"op\":\"add\",\"path\":\"/spec/ports/0/nodePort\",\"value\":${UI_NODE_PORT}}]"
   ```

3. Wait until the server answers from the machine, and from the lab:

   <!-- verify: timeout=90 expect="server v3" -->

   ```bash exec target=docker
   for i in $(seq 1 45); do wget -qO- http://127.0.0.1:${UI_PORT}/api/version > /dev/null 2>&1 && break; sleep 2; done; \
   wget -qO- http://127.0.0.1:${UI_PORT}/api/version | python3 -c 'import json,sys; print("server", json.load(sys.stdin)["Version"][:2])'
   ```

   <!-- verify: timeout=60 expect="from the lab: v3" -->

   ```bash exec
   wget -qO- http://docker:${UI_PORT}/api/version | python3 -c 'import json,sys; print("from the lab:", json.load(sys.stdin)["Version"][:2])'
   ```

4. The first password is generated at the installation, and kept in the Secret `argocd-initial-admin-secret`.
   The command line reads it:

   <!-- verify: expect="length: 16" -->

   ```bash exec target=docker
   echo "length: $(argocd admin initial-password --namespace argocd | head -1 | tr -d '\n' | wc -c)"
   ```

5. Log in with the command line, with `--plaintext` for the server that has no TLS, and check both versions:

   <!-- verify: timeout=60 expect="logged in successfully" -->

   ```bash exec target=docker
   argocd login 127.0.0.1:${UI_PORT} --plaintext --username admin --password "$(argocd admin initial-password --namespace argocd | head -1)"
   ```

   <!-- verify: expect="argocd-server: v3." -->

   ```bash exec target=docker
   argocd version --short
   ```

6. Replace the generated password with the one of the lab, which the browser types.
   The documentation says to delete the Secret of the generated one once the password is changed, since it stays readable by whoever reads the namespace:

   <!-- verify: expect="Password updated" -->

   ```bash exec target=docker
   argocd account update-password --current-password "$(argocd admin initial-password --namespace argocd | head -1)" --new-password "${UI_ADMIN_PASSWORD}" && \
   kubectl --namespace argocd delete secret argocd-initial-admin-secret > /dev/null
   ```

7. Open [Argo CD](:navigate:argocd:http://docker:8080), then [sign in as `admin`](:action:ui.login) with the click of a link: it fills the form of the page for you.
   The page lists **Applications**, and it is empty: Argo CD knows nothing yet.
   The left bar is the whole map of the interface: **Applications**, **ApplicationSets**, **Settings** (repositories, clusters, projects), **User Info** and **Documentation**.
