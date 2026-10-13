# Pull and reconcile

The reconciler runs next to the cluster and reads the repository, in a loop: it fetches the desired state, compares it with the actual state, and changes the cluster until they are equal.
Argo CD and Flux are this loop with a lot more care.
Here it is a short script, so every line can be read.

## A read-only credential

The reconciler only reads Git, so it does not need the password of an administrator.
Gitea makes a token for an account, with the scopes it needs:

1. Create a token that can read repositories and nothing else:

   <!-- verify: expect="token: 41 characters" -->

   ```bash exec target=docker
   mkdir -p ~/lab/gitops && cd ~/lab/gitops && \
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"reconciler","scopes":["read:repository"]}' \
     "${GITEA_BASE_URL}/api/v1/users/${GITEA_ADMIN_USER}/tokens" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha1"])' > token && \
   chmod 600 token && \
   echo "token: $(wc -c < token) characters"
   ```

2. The token reads, and it cannot write:

   <!-- verify: timeout=60 expect="read status: 200, write status: 403" -->

   ```bash exec target=docker
   cd ~/lab/gitops && \
   read_status=$(wget -S -qO- --user "${GITEA_ADMIN_USER}" --password "$(cat token)" --auth-no-challenge "${GITEA_BASE_URL}/api/v1/repos/${GITEA_ADMIN_USER}/platform" 2>&1 | awk '/HTTP\// {print $2}') ; \
   write_status=$(wget -S -qO- --user "${GITEA_ADMIN_USER}" --password "$(cat token)" --auth-no-challenge --header "Content-Type: application/json" --post-data '{"title":"x"}' "${GITEA_BASE_URL}/api/v1/repos/${GITEA_ADMIN_USER}/platform/issues" 2>&1 | awk '/HTTP\// {print $2}') ; \
   echo "read status: ${read_status}, write status: ${write_status}"
   ```

## The reconciler

1. Write the script.
   One pass fetches the branch, makes the working copy equal to it, applies the environment, and removes what the files no longer declare:

   <!-- verify: expect="-rwxr-xr-x" -->

   ```bash exec target=docker
   cd ~/lab/gitops && \
   tee reconcile.sh <<'EOT'
   #!/usr/bin/env bash
   # One pass of the loop: Git is read, the cluster is made equal to it, and nothing else is trusted.
   set -euo pipefail
   repo=$1
   path=$2
   copy=$HOME/lab/gitops/checkout

   # An empty credential helper keeps Git from storing the token of the URL in place of the account of the lab.
   git="git -c credential.helper="
   if [ -d "$copy/.git" ]; then
     $git -C "$copy" fetch --quiet origin main
     git -C "$copy" reset --quiet --hard origin/main
   else
     $git clone --quiet "$repo" "$copy"
   fi

   echo "revision $(git -C "$copy" rev-parse --short=7 HEAD)"
   # --prune deletes the objects of the listed kinds that carry the label and that no file declares anymore.
   kubectl apply -k "$copy/$path" --prune --selector app.kubernetes.io/managed-by=reconciler \
     --prune-allowlist core/v1/Service --prune-allowlist core/v1/ConfigMap --prune-allowlist apps/v1/Deployment
   EOT
   chmod +x reconcile.sh && \
   stat -c '%A' reconcile.sh
   ```

2. Run one pass by hand.
   The repository is cloned with the token, and everything is already as the files say:

   <!-- verify: timeout=60 expect="revision" -->

   ```bash exec target=docker
   cd ~/lab/gitops && \
   ./reconcile.sh "http://${GITEA_ADMIN_USER}:$(cat token)@127.0.0.1:3000/${GITEA_ADMIN_USER}/platform.git" envs/dev
   ```

   The drift of the previous step is gone: the third replica was removed.

3. Check the replicas:

   <!-- verify: expect="replicas in the cluster: 1" -->

   ```bash exec target=docker
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## The loop

1. Run the pass every 5 seconds, in the background, with its output in a file:

   ```bash exec target=docker
   cd ~/lab/gitops && \
   nohup bash -c 'while true; do ./reconcile.sh "http://${GITEA_ADMIN_USER}:$(cat token)@127.0.0.1:3000/${GITEA_ADMIN_USER}/platform.git" envs/dev 2>&1 | grep -v unchanged; sleep 5; done' > reconcile.log 2>&1 &
   ```

2. Commit a change: two replicas, in the file, not in the cluster:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   sed -i 's/replicas: 1/replicas: 2/' apps/shop/deployment.yaml && \
   git commit -q -am "Run two replicas of the shop" && \
   git push 2>&1
   ```

3. Nobody applies anything.
   The reconciler finds the commit and the cluster follows within a few seconds:

   <!-- verify: timeout=90 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

4. The log of the reconciler shows the revision it applied and what it changed:

   <!-- verify: expect="deployment.apps/shop configured" -->

   ```bash exec target=docker
   cat ~/lab/gitops/reconcile.log
   ```

## Drift is corrected

1. Change the cluster by hand again, to 5 replicas:

   <!-- verify: expect="scaled" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 5
   ```

2. The reconciler puts it back, with no commit:

   <!-- verify: timeout=90 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## Deletion

A file removed from Git is an object removed from the cluster, which is why the objects carry the label of the reconciler.
The kinds the reconciler may remove are listed in `--prune-allowlist`: the Kubernetes documentation calls this pruning alpha, and strongly encourages the list and the label.
The Namespace is not on the list, so it stays even when its file goes.

1. Add a second Service, wait for it, then remove its file:

   <!-- verify: timeout=90 expect="services: 2" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   tee apps/shop/extra-service.yaml <<EOT
   apiVersion: v1
   kind: Service
   metadata:
     name: extra
   spec:
     selector:
       app: shop
     ports:
       - port: 80
   EOT
   sed -i 's/  - service.yaml/  - service.yaml\n  - extra-service.yaml/' apps/shop/kustomization.yaml && \
   git add . && git commit -q -m "Add a second Service" && git push -q && \
   for i in $(seq 1 30); do kubectl --namespace shop get service extra > /dev/null 2>&1 && break; sleep 2; done; \
   echo "services: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```

2. Remove it from the repository:

   <!-- verify: timeout=90 expect="services: 1" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git rm -q apps/shop/extra-service.yaml && \
   sed -i '/extra-service.yaml/d' apps/shop/kustomization.yaml && \
   git commit -q -am "Remove the second Service" && git push -q && \
   for i in $(seq 1 30); do kubectl --namespace shop get service extra > /dev/null 2>&1 || break; sleep 2; done; \
   echo "services: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```
