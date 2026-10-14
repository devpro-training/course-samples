# Two clusters

The repository describes every cluster, one folder each, and each cluster runs its own Flux that follows its own folder.
A second cluster, `staging`, is added to the repository of the hub: it shares the folders of the applications, differs by one patch, and holds its own key for the secrets.

## A second cluster

1. Create the cluster `staging`.
   It joins the Docker network of the hub, as the other k3d clusters of the series, and the context of `kubectl` stays on the hub:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create staging --image "${NODE_IMAGE}" --network k3d-hub \
     --k3s-arg "--disable=traefik,metrics-server@server:*" --kubeconfig-switch-context=false
   ```

2. Wait until its node is ready, and list the contexts of the machine:

   <!-- verify: timeout=120 expect="staging nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl --context k3d-staging get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "staging nodes: $(kubectl --context k3d-staging get nodes | grep -c ' Ready')" && \
   kubectl config get-contexts --output name
   ```

## Bootstrap it

1. The same command, with another context and another folder.
   The bootstrap clones the repository, adds `clusters/staging/flux-system`, and pushes:

   <!-- verify: requires=network timeout=300 expect="all components are healthy" -->

   ```bash exec target=docker
   flux bootstrap git --context k3d-staging --url "${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/fleet.git" --branch main --path clusters/staging \
     --token-auth --username "${GITEA_ADMIN_USER}" --password "$(cat ~/lab/flux-token)" --allow-insecure-http --silent
   ```

2. The local clone is behind by that commit.
   Fetch it, and list the folders of the clusters:

   <!-- verify: expect="clusters/staging/flux-system/gotk-sync.yaml" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git pull -q --rebase && find clusters -name gotk-sync.yaml | sort
   ```

## The same applications, a different replica count

1. The layers of the staging are the files of the hub, copied.
   Only `shop` differs, by an inline patch in the `Kustomization`, which sets one replica:

   <!-- verify: expect="staging files: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && cp clusters/hub/infra.yaml clusters/staging/infra.yaml && cp clusters/hub/shop.yaml clusters/staging/shop.yaml && \
   cat >> clusters/staging/shop.yaml <<EOT
     patches:
       - target:
           kind: Deployment
           name: shop
         patch: |-
           - op: replace
             path: /spec/replicas
             value: 1
   EOT
   echo "staging files: $(ls clusters/staging/*.yaml | wc -l)"
   ```

2. The secret of the shop is encrypted for the key of the hub only, and staging has to read it too, with a key of its own.
   Make the key, and give the private part to the cluster staging only:

   <!-- verify: expect="secret/sops-age created" -->

   ```bash exec target=docker
   cd ~/lab && age-keygen -o staging.agekey 2> /dev/null ; chmod 600 staging.agekey && \
   kubectl --context k3d-staging --namespace flux-system create secret generic sops-age --from-file=age.agekey=$HOME/lab/staging.agekey
   ```

3. Add its public key to the rules of SOPS, and re-encrypt the file: the data key is encrypted once for each recipient, and the values are not re-encrypted:

   <!-- verify: expect="recipients in the file: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   sed -i "s#^\(    age: .*\)#\1,$(age-keygen -y ~/lab/staging.agekey)#" .sops.yaml && \
   SOPS_AGE_KEY_FILE=$HOME/lab/age.agekey sops updatekeys --yes apps/shop/secret.yaml > /dev/null 2>&1 ; \
   echo "recipients in the file: $(grep -c '    recipient: age1' apps/shop/secret.yaml)"
   ```

4. Each key opens the file, and a key nobody listed does not:

   <!-- verify: expect="hub key: ok" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   echo "hub key: $(SOPS_AGE_KEY_FILE=$HOME/lab/age.agekey sops decrypt apps/shop/secret.yaml > /dev/null 2>&1 && echo ok)" && \
   echo "staging key: $(SOPS_AGE_KEY_FILE=$HOME/lab/staging.agekey sops decrypt apps/shop/secret.yaml > /dev/null 2>&1 && echo ok)" && \
   age-keygen -o ~/lab/stranger.agekey 2> /dev/null ; \
   echo "stranger key: $(SOPS_AGE_KEY_FILE=$HOME/lab/stranger.agekey sops decrypt apps/shop/secret.yaml > /dev/null 2>&1 && echo ok || echo refused)"
   ```

5. Commit, and push.
   Both clusters read the same repository, each on its own folder:

   <!-- verify: expect="in sync: yes" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Add the staging cluster" && git push -q && \
   echo "in sync: $([ "$(git rev-parse HEAD)" = "$(git ls-remote origin main | cut -f 1)" ] && echo yes)"
   ```

## Each cluster, its own state

1. The staging cluster applies its folder, layer after layer:

   <!-- verify: timeout=300 expect="staging ready: 3" -->

   ```bash exec target=docker
   flux --context k3d-staging reconcile kustomization flux-system --with-source --timeout 60s > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do [ "$(flux --context k3d-staging get kustomizations 2> /dev/null | grep -c True)" = 3 ] && break; sleep 5; done; \
   echo "staging ready: $(flux --context k3d-staging get kustomizations | grep -c True)"
   ```

2. The same file, two results: one replica in the staging, three in the hub:

   <!-- verify: expect="staging replicas: 1" -->

   ```bash exec target=docker
   echo "staging replicas: $(kubectl --context k3d-staging --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   echo "hub replicas: $(kubectl --context k3d-hub --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

3. And the secret is in both, decrypted by the key of each:

   <!-- verify: expect="staging password: s3cr3t-lab-value" -->

   ```bash exec target=docker
   echo "staging password: $(kubectl --context k3d-staging --namespace shop get secret shop-db --output jsonpath='{.data.password}' | base64 -d)"
   ```

4. A change of the repository reaches both clusters at the next reconciliation, with no command run against either of them.
   The cluster that follows the repository is the one that is told, and a cluster that was off catches up when it is back.
