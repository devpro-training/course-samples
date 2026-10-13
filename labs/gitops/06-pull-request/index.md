# Change by pull request

The reconciler applies what is on `main`, so a change reaches the cluster when it is merged.
A pull request is the place where it is read, discussed and approved first, and the history of `main` is the history of the cluster.

## A branch changes nothing

1. Make the change on a branch: a new version of the application.
   The branch is pushed to the server, and the cluster does not move:

   <!-- verify: timeout=60 expect="shop-v2 -> shop-v2" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git switch -q -c shop-v2 && \
   sed -i 's/shop v1/shop v2/' apps/shop/deployment.yaml && \
   git commit -q -am "Announce the version 2 of the shop" && \
   git push -u origin shop-v2 2>&1 | grep -e "->"
   ```

2. Wait longer than a pass of the reconciler, then read the application:

   <!-- verify: timeout=60 expect="name of the shop: shop v1" -->

   ```bash exec target=docker
   sleep 12; \
   echo "name of the shop: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.template.spec.containers[0].env[0].value}')"
   ```

## The pull request

1. Open it through the API:

   <!-- verify: timeout=60 expect="pull request 1" -->

   ```bash exec target=docker
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"title":"Shop version 2","head":"shop-v2","base":"main"}' \
     "${GITEA_BASE_URL}/api/v1/repos/${GITEA_ADMIN_USER}/platform/pulls" | python3 -c 'import json,sys; print("pull request", json.load(sys.stdin)["number"])'
   ```

2. The reviewer reads the difference.
   It is the whole change to the cluster, a few lines of YAML:

   <!-- verify: timeout=60 expect="+++ b/apps/shop/deployment.yaml" -->

   ```bash exec target=docker
   wget -qO- "${GITEA_BASE_URL}/${GITEA_ADMIN_USER}/platform/pulls/1.diff" | grep -E '^(\+\+\+|[-+] )'
   ```

   > [!NOTE]
   > On a real server, the branch `main` is protected: a merge needs a review and a green check, and nobody pushes to it directly.
   > That is where the approval of a change to production lives.

3. Merge it:

   <!-- verify: timeout=60 expect="status 200" -->

   ```bash exec target=docker
   wget -S -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"Do":"merge"}' \
     "${GITEA_BASE_URL}/api/v1/repos/${GITEA_ADMIN_USER}/platform/pulls/1/merge" 2>&1 | awk '/HTTP\// {print "status", $2}'
   ```

4. The reconciler applies the merge commit:

   <!-- verify: timeout=90 expect="name of the shop: shop v2" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.template.spec.containers[0].env[0].value}')" = "shop v2" ] && break; sleep 2; done; \
   echo "name of the shop: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.template.spec.containers[0].env[0].value}')"
   ```

## Rollback

The previous state is one commit away, and the rollback is a commit like the others: it leaves a trace, and it is reviewed like the others.

1. Revert the merge on `main`:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git switch -q main && git pull -q && \
   git revert --no-edit --mainline 1 HEAD > /dev/null && \
   git push 2>&1
   ```

2. The cluster goes back to the version 1:

   <!-- verify: timeout=90 expect="name of the shop: shop v1" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.template.spec.containers[0].env[0].value}')" = "shop v1" ] && break; sleep 2; done; \
   echo "name of the shop: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.template.spec.containers[0].env[0].value}')"
   ```

3. The history of `main` tells what was deployed, when, by whom, and why:

   <!-- verify: expect="Revert" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git log --oneline --max-count 6
   ```
