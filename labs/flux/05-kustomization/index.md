# Kustomization

The chart of the previous step was packaged by someone else.
The manifests a team writes itself are plain YAML in a folder, and Flux applies them with the same kind of object that delivered the `HelmRelease`.
An application is a folder of manifests, and a `Kustomization` is the object that tells Flux which folder to apply, from which source, and how often.
The first application is `shop`, a web server that prints the request it receives.

## The application

1. Write the folder `apps/shop`: a namespace, a Deployment of one replica, a Service, and the `kustomization.yaml` of Kustomize that lists them:

   <!-- verify: expect="apps/shop/kustomization.yaml" -->

   ```bash exec target=docker
   mkdir -p ~/lab/fleet/apps/shop && cd ~/lab/fleet/apps/shop && \
   cat > namespace.yaml <<EOT
   apiVersion: v1
   kind: Namespace
   metadata:
     name: shop
   EOT
   cat > deployment.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: shop
     namespace: shop
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
           - name: web
             image: ${WHOAMI_IMAGE}
             ports:
               - containerPort: 80
   EOT
   cat > service.yaml <<EOT
   apiVersion: v1
   kind: Service
   metadata:
     name: shop
     namespace: shop
   spec:
     selector:
       app: shop
     ports:
       - port: 80
   EOT
   cat > kustomization.yaml <<EOT
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - namespace.yaml
     - deployment.yaml
     - service.yaml
   EOT
   cd ~/lab/fleet && find apps -type f | sort
   ```

   There are two kinds named `Kustomization`: this one is the file of Kustomize, in the folder of the application, and the next is the object of Flux, in the cluster.
   The groups of their `apiVersion` tell them apart.

## The object that applies it

1. Ask `flux` to write the object, instead of typing it.
   `--export` prints it without creating anything in the cluster, and the file goes in the folder the bootstrap follows, `clusters/hub`:

   <!-- verify: expect="path: ./apps/shop" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   flux create kustomization shop --source GitRepository/flux-system --path ./apps/shop --prune true --interval 1m --wait true --export > clusters/hub/shop.yaml && \
   cat clusters/hub/shop.yaml
   ```

   - `--source` names the `GitRepository` of the bootstrap: one fetch of the repository serves every Kustomization.
   - `--prune true` deletes from the cluster what disappears from Git.
   - `--wait true` makes the Kustomization ready only when what it applied is ready.
   - `--interval 1m` is the lowest value the documentation allows.

2. Commit and push.
   Nothing is applied by hand: the bootstrap Kustomization sees the new file in `clusters/hub` and applies it, which creates this Kustomization, which applies the application:

   <!-- verify: expect="in sync: yes" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Add the shop application" && git push -q && \
   echo "in sync: $([ "$(git rev-parse HEAD)" = "$(git ls-remote origin main | cut -f 1)" ] && echo yes)"
   ```

3. Flux looks at the repository every minute.
   `flux reconcile` asks it to look now, and `--with-source` fetches the repository first:

   <!-- verify: requires=network timeout=180 expect="applied revision" -->

   ```bash exec target=docker
   flux reconcile kustomization flux-system --with-source 2>&1 | tail -1
   for i in $(seq 1 60); do kubectl get kustomization shop --namespace flux-system > /dev/null 2>&1 && break; sleep 2; done
   flux reconcile kustomization shop 2>&1 | tail -1
   ```

4. The result, as `flux` and as `kubectl` show it:

   <!-- verify: expect="Applied revision: main@sha1:" -->

   ```bash exec target=docker
   flux get kustomizations shop
   ```

   <!-- verify: timeout=120 expect="shop-" -->

   ```bash exec target=docker
   kubectl --namespace shop wait deployment shop --for=condition=Available --timeout=100s > /dev/null && kubectl --namespace shop get pods
   ```

5. Flux keeps an inventory of what it applied, in the status of the object.
   It is what lets `prune` delete exactly what Flux created, and nothing else:

   <!-- verify: expect="shop_shop_apps_Deployment" -->

   ```bash exec target=docker
   kubectl --namespace flux-system get kustomization shop --output jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
   ```

## A change in Git

1. Two replicas, in the file, then a commit:

   <!-- verify: expect="replicas in the file: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && sed -i 's/replicas: 1/replicas: 2/' apps/shop/deployment.yaml && \
   git commit -q -am "Run two replicas of the shop" && git push -q && \
   echo "replicas in the file: $(grep -o 'replicas: [0-9]*' apps/shop/deployment.yaml | cut -d ' ' -f 2)"
   ```

2. Fetch and apply, then count the Pods:

   <!-- verify: timeout=120 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   flux reconcile kustomization shop --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## Drift

1. Change the cluster by hand, as someone would at three in the morning:

   <!-- verify: expect="replicas after the hand: 5" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 5 > /dev/null && \
   echo "replicas after the hand: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

2. Flux compares at each interval, with a server side dry run, and corrects what differs.
   The request makes it happen now:

   <!-- verify: timeout=120 expect="replicas after Flux: 2" -->

   ```bash exec target=docker
   flux reconcile kustomization shop > /dev/null 2>&1 ; \
   echo "replicas after Flux: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

3. A Kustomization can be paused, for an incident for instance.
   While it is suspended nothing is applied, and the drift stays:

   <!-- verify: expect="replicas while suspended: 5" -->

   ```bash exec target=docker
   flux suspend kustomization shop > /dev/null && \
   kubectl --namespace shop scale deployment shop --replicas 5 > /dev/null && \
   flux reconcile kustomization shop > /dev/null 2>&1 ; \
   echo "replicas while suspended: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

4. Resume it, and Git wins again:

   <!-- verify: timeout=120 expect="replicas after the resume: 2" -->

   ```bash exec target=docker
   flux resume kustomization shop > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas after the resume: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## Prune, and a revert

1. Remove the Service from the folder and from the list, and push:

   <!-- verify: expect="resources in the list: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git rm -q apps/shop/service.yaml && sed -i '/service.yaml/d' apps/shop/kustomization.yaml && \
   git commit -q -am "Remove the service" && git push -q && \
   echo "resources in the list: $(grep -c '^  - ' apps/shop/kustomization.yaml)"
   ```

2. The object is gone from the cluster too, since the inventory says Flux made it:

   <!-- verify: timeout=120 expect="services after the prune: 0" -->

   ```bash exec target=docker
   flux reconcile kustomization shop --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do kubectl --namespace shop get service shop > /dev/null 2>&1 || break; sleep 2; done; \
   echo "services after the prune: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```

3. The way back is a Git revert, a new commit that undoes the last one, so the history keeps both:

   <!-- verify: timeout=120 expect="services after the revert: 1" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git revert --no-edit HEAD > /dev/null && git push -q && \
   flux reconcile kustomization shop --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do kubectl --namespace shop get service shop > /dev/null 2>&1 && break; sleep 2; done; \
   echo "services after the revert: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```
