# A repository for the cluster

GitOps starts with a repository that says what the cluster must look like.
The files describe the result, not the commands to reach it, and Git keeps every version of them.

## The cluster

1. Create a cluster.
   Traefik is disabled: nothing in this lab needs it, and the cluster starts faster and uses less memory:

   <!-- verify: requires=network timeout=300 expect="created successfully" -->

   ```bash exec target=docker
   k3d cluster create gitops --image "${NODE_IMAGE}" --k3s-arg "--disable=traefik@server:*"
   ```

2. Wait until the node is ready:

   <!-- verify: timeout=120 expect="ready nodes: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl get nodes 2> /dev/null | grep -q " Ready" && break; sleep 2; done; \
   echo "ready nodes: $(kubectl get nodes | grep -c ' Ready')"
   ```

## The repository

1. Let Git use the account of the lab with every request to the server, instead of a password typed or written in each URL:

   <!-- verify: expect="http://ada:" -->

   ```bash exec target=docker
   git config --global credential.helper store && \
   echo "http://${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}@127.0.0.1:3000" > ~/.git-credentials && \
   chmod 600 ~/.git-credentials && \
   cut -c 1-12 ~/.git-credentials
   ```

2. Create the repository `platform` through the API of Gitea.
   The answer is a JSON document, of which the URL to clone is enough:

   <!-- verify: timeout=60 expect="platform.git" -->

   ```bash exec target=docker
   wget -qO- --user "${GITEA_ADMIN_USER}" --password "${GITEA_ADMIN_PASSWORD}" --auth-no-challenge \
     --header "Content-Type: application/json" \
     --post-data '{"name":"platform","default_branch":"main"}' \
     "${GITEA_BASE_URL}/api/v1/user/repos" | grep -o '"clone_url":"[^"]*"'
   ```

3. Clone it.
   It is empty, and Git says so:

   <!-- verify: timeout=60 expect="empty repository" -->

   ```bash exec target=docker
   mkdir -p ~/lab/gitops && cd ~/lab/gitops && \
   git clone "${GITEA_BASE_URL}/${GITEA_ADMIN_USER}/platform.git" 2>&1
   ```

## The desired state

The application is described once, in `apps/shop`, and an environment, `envs/dev`, says where and how it runs.
Each file is a Kubernetes resource, and `kustomization.yaml` lists them: Kustomize, built into `kubectl`, assembles the folders and applies the differences of an environment.

1. Write the application, a Deployment and a Service.
   `whoami` is a web server that prints the request it receives:

   <!-- verify: expect="files in apps/shop: 3" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && mkdir -p apps/shop envs/dev && \
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
             env:
               - name: WHOAMI_NAME
                 value: shop v1
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
   tee apps/shop/kustomization.yaml <<EOT
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - deployment.yaml
     - service.yaml
   EOT
   echo "files in apps/shop: $(ls apps/shop | wc -l)"
   ```

2. Write the environment.
   It creates the namespace, puts the application in it, and labels everything with the name of the reconciler that owns it, which is how that reconciler will find what to remove one day:

   <!-- verify: expect="files in envs/dev: 2" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   tee envs/dev/namespace.yaml <<EOT
   apiVersion: v1
   kind: Namespace
   metadata:
     name: shop
   EOT
   tee envs/dev/kustomization.yaml <<EOT
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   namespace: shop
   resources:
     - namespace.yaml
     - ../../apps/shop
   labels:
     - pairs:
         app.kubernetes.io/managed-by: reconciler
   EOT
   echo "files in envs/dev: $(ls envs/dev | wc -l)"
   ```

3. Render the environment without applying it.
   This is the exact content that would reach the cluster, with the namespace and the label added to each resource:

   <!-- verify: expect="labelled resources: 3" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   kubectl kustomize envs/dev && \
   echo "labelled resources: $(kubectl kustomize envs/dev | grep -c 'managed-by')"
   ```

## The history

1. Commit the files and push them to the server.
   Every later change to the cluster is a commit like this one:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git add . && \
   git commit -q -m "Add the shop application and the dev environment" && \
   git branch -M main && \
   git push -u origin main 2>&1
   ```

2. The server holds the same commit.
   `git ls-remote` asks it for its branches and the commit each one points to:

   <!-- verify: timeout=60 expect="refs/heads/main" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   git ls-remote origin && \
   git rev-parse HEAD
   ```
