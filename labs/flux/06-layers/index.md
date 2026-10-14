# Layers

A cluster needs its platform before its applications: the namespaces, the policies, the controllers.
Flux orders them with `dependsOn`, and with `wait`, which makes an object ready only when what it applied is ready.

## A platform layer

1. Write the layer `infra`: a namespace and a Deployment, standing for the controllers a real platform has:

   <!-- verify: expect="apps/infra/kustomization.yaml" -->

   ```bash exec target=docker
   mkdir -p ~/lab/fleet/apps/infra && cd ~/lab/fleet/apps/infra && \
   cat > namespace.yaml <<EOT
   apiVersion: v1
   kind: Namespace
   metadata:
     name: platform
   EOT
   cat > deployment.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: gateway
     namespace: platform
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: gateway
     template:
       metadata:
         labels:
           app: gateway
       spec:
         containers:
           - name: web
             image: ${WHOAMI_IMAGE}
   EOT
   cat > kustomization.yaml <<EOT
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - namespace.yaml
     - deployment.yaml
   EOT
   cd ~/lab/fleet && find apps/infra -type f | sort
   ```

2. Two Kustomizations: `infra`, which waits for what it applies, and `shop`, written again so that it depends on it.
   The field `timeout` bounds the wait, so a layer that never gets ready fails instead of hanging.
   The `--timeout` flag of `flux` is how long the command waits, not this field, so the file is edited:

   <!-- verify: expect="path: ./apps/infra" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   flux create kustomization infra --source GitRepository/flux-system --path ./apps/infra --prune true --interval 1m --wait true --export > clusters/hub/infra.yaml && \
   sed -i 's/^  timeout: .*/  timeout: 40s/' clusters/hub/infra.yaml && \
   flux create kustomization shop --source GitRepository/flux-system --path ./apps/shop --prune true --interval 1m --wait true --depends-on infra --export > clusters/hub/shop.yaml && \
   grep -E " (path|timeout):" clusters/hub/infra.yaml; grep -A1 dependsOn clusters/hub/shop.yaml
   ```

3. Commit, and let Flux apply both:

   <!-- verify: timeout=180 expect="infra and shop ready: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Add the platform layer, the shop depends on it" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do [ "$(flux get kustomizations 2> /dev/null | grep -E '^(infra|shop)' | grep -c 'True')" = 2 ] && break; sleep 3; done; \
   echo "infra and shop ready: $(flux get kustomizations | grep -E '^(infra|shop)' | grep -c 'True')"
   ```

4. The objects of Flux form a tree, from the bootstrap Kustomization down to the Pods' owners:

   <!-- verify: expect="Deployment/platform/gateway" -->

   ```bash exec target=docker
   flux tree kustomization flux-system | grep -E "Kustomization/|Deployment/(platform|shop)/"
   ```

## A broken layer

1. Point the platform to an image that does not exist, as a typo would:

   <!-- verify: expect="image in the file: whoami:v9.9.9" -->

   ```bash exec target=docker
   cd ~/lab/fleet && sed -i 's#traefik/whoami:[0-9.v]*#traefik/whoami:v9.9.9#' apps/infra/deployment.yaml && \
   git commit -q -am "Update the gateway" && git push -q && \
   echo "image in the file: $(grep -o 'whoami:v9.9.9' apps/infra/deployment.yaml)"
   ```

2. Change the shop too, in the next commit: three replicas.
   `infra` waits 40 seconds for a Deployment that never becomes ready, then says so:

   <!-- verify: timeout=240 expect="health check failed" -->

   ```bash exec target=docker
   cd ~/lab/fleet && sed -i 's/replicas: 2/replicas: 3/' apps/shop/deployment.yaml && \
   git commit -q -am "Run three replicas of the shop" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do [ "$(kubectl --namespace flux-system get kustomization infra --output jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = False ] && break; sleep 3; done; \
   flux get kustomization infra | tail -1 | cut -f 5 | cut -c 1-160
   ```

3. The shop does not move.
   The change is in Git and in the source, and the layer below is not ready, so the controller says what it waits for:

   <!-- verify: timeout=120 expect="dependency 'flux-system/infra' is not ready" -->

   ```bash exec target=docker
   flux reconcile kustomization shop --timeout 20s > /dev/null 2>&1 ; \
   flux get kustomization shop | tail -1 | cut -f 5 | cut -c 1-160
   echo "shop replicas: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

4. Fix the image with a revert of the typo, and both layers come back, in order:

   <!-- verify: timeout=240 expect="shop replicas after the fix: 3" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git revert --no-edit HEAD~1 > /dev/null 2>&1 ; git push -q ; \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   flux reconcile kustomization infra --timeout 60s > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 3 ] && break; flux reconcile kustomization shop --timeout 20s > /dev/null 2>&1 ; sleep 3; done; \
   echo "shop replicas after the fix: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```
