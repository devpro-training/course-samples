# An application

An `Application` says where the manifests are and where they go.
Argo CD then keeps two states side by side: what the repository says, and what the cluster holds.

## The repository

1. Let Git use the account of the lab with every request to the server:

   <!-- verify: expect="http://ada:" -->

   ```bash exec target=docker
   git config --global credential.helper store && \
   echo "http://${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}@127.0.0.1:3000" > ~/.git-credentials && \
   chmod 600 ~/.git-credentials && \
   cut -c 1-12 ~/.git-credentials
   ```

2. Create the repository `deploy` through the API of Gitea, and clone it:

   <!-- verify: timeout=60 expect="empty repository" -->

   ```bash exec target=docker
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"deploy","default_branch":"main"}' \
     "${GITEA_BASE_URL}/api/v1/user/repos" > /dev/null && \
   mkdir -p ~/lab/argocd && cd ~/lab/argocd && \
   git clone "${GITEA_BASE_URL}/${GITEA_ADMIN_USER}/deploy.git" 2>&1
   ```

3. Write the application, a Deployment and a Service of plain YAML, and push them.
   `whoami` is a web server that prints the request it receives:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && mkdir -p apps/shop && \
   tee apps/shop/deployment.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: shop
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
           - name: shop
             image: ${WHOAMI_IMAGE}
   EOT
   tee apps/shop/service.yaml <<EOT
   apiVersion: v1
   kind: Service
   metadata:
     name: shop
   spec:
     selector:
       app: shop
     ports:
       - port: 80
   EOT
   git add . && git commit -q -m "Add the shop" && git branch -M main && git push -u origin main 2>&1
   ```

## A read-only credential

Argo CD only reads Git, so it does not need the password of an administrator.
Gitea makes a token for an account, with the scopes it needs, and the repository is declared to Argo CD as a Secret of its namespace, with a label that says what it is.
The address is the one the cluster reaches, `host.k3d.internal`, and not the loopback of the machine.

1. Create a token that can read repositories and nothing else:

   <!-- verify: expect="token: 41 characters" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"argocd","scopes":["read:repository"]}' \
     "${GITEA_BASE_URL}/api/v1/users/${GITEA_ADMIN_USER}/tokens" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha1"])' > token && \
   chmod 600 token && \
   echo "token: $(wc -c < token) characters"
   ```

2. Declare the repository:

   <!-- verify: expect="secret/repo-deploy created" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   kubectl apply -f - <<EOT
   apiVersion: v1
   kind: Secret
   metadata:
     name: repo-deploy
     namespace: argocd
     labels:
       argocd.argoproj.io/secret-type: repository
   stringData:
     type: git
     url: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
     username: ${GITEA_ADMIN_USER}
     password: $(cat token)
   EOT
   ```

3. Argo CD tries the connection, and the status says whether it works:

   <!-- verify: timeout=60 expect="Successful" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do argocd repo list 2> /dev/null | grep -q Succ && break; sleep 2; done; \
   argocd repo list
   ```

## The application

1. Declare it.
   The source is a folder of the repository, the destination is the cluster Argo CD runs in, and `CreateNamespace` makes the namespace `shop` at the first sync.
   There is no `syncPolicy.automated`, so nothing is applied until someone says so:

   <!-- verify: expect="application.argoproj.io/shop created" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   tee shop-application.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: shop
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
       targetRevision: main
       path: apps/shop
     destination:
       server: https://kubernetes.default.svc
       namespace: shop
     syncPolicy:
       syncOptions:
         - CreateNamespace=true
   EOT
   kubectl apply -f shop-application.yaml
   ```

2. The application exists and nothing runs.
   Its sync status is `OutOfSync`, and its health is `Missing`, since the cluster holds none of its resources:

   <!-- verify: timeout=60 expect="OutOfSync" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do argocd app get shop 2> /dev/null | grep -q "^Sync Status: *[A-Z]" && break; sleep 2; done; \
   argocd app get shop | grep -E "^(Sync Status|Health Status)"
   ```

3. In the web interface, [open the shop](:action:ui.open-shop) from the **Applications** page.
   The tree shows what Argo CD found in the repository: a Deployment and a Service, each marked as out of sync.
   The page has two states, side by side, and they are the two questions Argo CD answers:

   Status    | Question                    | Values
   ----------|-----------------------------|-------------------------------------------------------------
   Sync      | Does the cluster match Git? | `Synced`, `OutOfSync`, `Unknown`
   Health    | Is what runs working?       | `Healthy`, `Progressing`, `Degraded`, `Missing`, `Suspended`
   Operation | What did the last sync do?  | `Sync OK`, `Sync failed`, `Syncing`

## Sync

1. Read the difference first.
   `argocd app diff` exits with 1 when there is one, as `kubectl diff` does, and prints the resources it would create:

   <!-- verify: expect="===== " -->

   ```bash exec target=docker
   { argocd app diff shop || true; } | head -12
   ```

   The interface shows the same in [its **DIFF** view](:action:ui.diff), with a compact view of what differs and an inline view of the whole manifest.

2. Sync:

   <!-- verify: timeout=120 expect="successfully synced" -->

   ```bash exec target=docker
   argocd app sync shop | grep -E "^(Message|Phase)"
   ```

   The same is done in the interface: [press **SYNC**, then **SYNCHRONIZE**](:action:ui.sync).
   The panel offers what the command line takes as options: prune, dry run, force, and the resources to sync, one by one.

3. Wait for the Pod, and read both states:

   <!-- verify: timeout=120 expect="Healthy" -->

   ```bash exec target=docker
   argocd app wait shop --health --timeout 100 > /dev/null; \
   argocd app get shop | grep -E "^(Sync Status|Health Status)"
   ```

   The Namespace, the Service and the Deployment are green in the tree, down to the ReplicaSet and the Pod that Kubernetes made from them.

4. Every node of the tree opens a panel.
   [Open the Deployment](:action:ui.open-deployment): **Summary** has its labels and images, **Events** what Kubernetes said, **Live manifest** the object as it is in the cluster, **Desired manifest** the one rendered from Git,
   and **Diff** the difference.
   For a Pod, [**Logs**](:action:ui.pod-logs) shows the output of the container, with no `kubectl`, which is what lets a team without access to the cluster read what runs.
   **Hide managed fields** keeps the live manifest readable, without the bookkeeping Kubernetes adds.

## A change in Git

1. Run two replicas, in the file, and push:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   sed -i 's/replicas: 1/replicas: 2/' apps/shop/deployment.yaml && \
   git commit -q -am "Run two replicas of the shop" && \
   git push 2>&1
   ```

2. Argo CD looks at the repository every 3 minutes at most, and a refresh asks it now.
   The application is `OutOfSync` again, the cluster is untouched, and the diff is the line that changed:

   <!-- verify: timeout=60 expect="replicas: 2" -->

   ```bash exec target=docker
   argocd app get shop --refresh | grep -E "^Sync Status" ; \
   { argocd app diff shop || true; } | grep -E "^[<>] +replicas"
   ```

3. Sync again, and the cluster follows:

   <!-- verify: timeout=120 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   argocd app sync shop > /dev/null && \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## History and rollback

Each sync is kept in the history of the application, with the commit it applied.

1. List it:

   <!-- verify: expect="REVISION" -->

   ```bash exec target=docker
   argocd app history shop
   ```

2. Go back to the first sync, and read the cluster and the application.
   The interface lists the same history in [**HISTORY AND ROLLBACK**](:action:ui.history), one card per sync: when, how long it took, who started it (a person, or the automated sync policy), the commit with its author,
   and whether its GPG signature was checked, with a menu on each card that holds the rollback:

   <!-- verify: timeout=120 expect="replicas in the cluster: 1" -->

   ```bash exec target=docker
   argocd app rollback shop 0 > /dev/null && \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" && \
   argocd app get shop | grep -E "^Sync Status"
   ```

   The cluster runs the old version, and the application is `OutOfSync`: the repository still says two replicas, so a rollback is a state of the cluster for a while, and not a change of the truth.
   The real rollback is a revert in Git.

3. Sync again to bring the cluster back to the repository:

   <!-- verify: timeout=120 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   argocd app sync shop > /dev/null && \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```
