# Bootstrap

A new cluster has an Argo CD and nothing to deploy, and the applications need things that other applications bring: a namespace, a controller, definitions.
Who creates the first Application, and in which order do the others come?
The pattern is a root Application, the only one made by hand, that points to a folder of Git holding the others, in layers.

## The layers

The repository gets two more folders.
`platform` is what the others need, and `apps` holds one folder per application: the shop, and a blog.

1. Write the platform and the blog:

   <!-- verify: expect="folders in apps: 2" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && mkdir -p platform apps/blog && \
   tee platform/info.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: info
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: info
     template:
       metadata:
         labels:
           app: info
       spec:
         containers:
           - name: info
             image: ${WHOAMI_IMAGE}
   EOT
   sed 's/name: shop/name: blog/; s/app: shop/app: blog/' apps/shop/deployment.yaml > apps/blog/deployment.yaml
   sed 's/name: shop/name: blog/; s/app: shop/app: blog/' apps/shop/service.yaml > apps/blog/service.yaml
   echo "folders in apps: $(ls apps | wc -l)"
   ```

2. Write the layers.
   `bootstrap` holds an Application for the platform, and an ApplicationSet that makes one Application per folder of `apps`: its generator reads the repository.
   The annotation `argocd.argoproj.io/sync-wave` orders them, the lowest first.
   The path of the platform has a typo, on purpose:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && mkdir -p bootstrap && \
   tee bootstrap/platform.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: platform
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "0"
   spec:
     project: default
     source:
       repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
       targetRevision: main
       path: platfrom
     destination:
       server: https://kubernetes.default.svc
       namespace: platform
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   EOT
   tee bootstrap/apps.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: ApplicationSet
   metadata:
     name: apps
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "1"
   spec:
     goTemplate: true
     goTemplateOptions: ["missingkey=error"]
     generators:
       - git:
           repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
           revision: main
           directories:
             - path: apps/*
     template:
       metadata:
         name: '{{.path.basename}}'
       spec:
         project: default
         source:
           repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
           targetRevision: main
           path: '{{.path.path}}'
         destination:
           server: https://kubernetes.default.svc
           namespace: '{{.path.basename}}'
         syncPolicy:
           automated:
             prune: true
             selfHeal: true
           syncOptions:
             - CreateNamespace=true
   EOT
   git add . && git commit -q -m "Add the platform, the blog and the layers" && git push 2>&1
   ```

   `{{.path.basename}}` is the name of the folder, so `apps/shop` becomes the Application `shop` that deploys to the namespace `shop`.

## The root

1. The Application of the shop was made by hand in the previous steps, and the ApplicationSet is going to make it.
   Deleting an Application that has no finalizer leaves its resources in the cluster, so the new one finds them as they are:

   <!-- verify: expect="applications: 0" -->

   ```bash exec target=docker
   kubectl --namespace argocd delete application shop > /dev/null && \
   echo "applications: $(kubectl --namespace argocd get applications --no-headers | wc -l)"
   ```

2. Declare the root, the one Application made by hand.
   It points to the folder `bootstrap`, and is synced by hand for now:

   <!-- verify: expect="application.argoproj.io/root created" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   tee root-application.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: root
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
       targetRevision: main
       path: bootstrap
     destination:
       server: https://kubernetes.default.svc
       namespace: argocd
   EOT
   kubectl apply -f root-application.yaml
   ```

3. Sync it.
   The platform is broken, so the apps should wait for it:

   <!-- verify: timeout=120 expect="applicationsets: 1" -->

   ```bash exec target=docker
   for i in $(seq 1 20); do argocd app get root 2> /dev/null | grep -q "Sync Status" && break; sleep 2; done; \
   argocd app sync root > /dev/null; \
   for i in $(seq 1 30); do kubectl --namespace argocd get applicationset apps > /dev/null 2>&1 && break; sleep 2; done; \
   echo "applicationsets: $(kubectl --namespace argocd get applicationsets --no-headers | wc -l)"
   ```

4. They did not wait.
   The ApplicationSet was created and made its Applications, while the platform cannot read its folder:

   <!-- verify: timeout=60 expect="argocd/blog" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(argocd app list -o name 2> /dev/null | wc -l)" = 4 ] && break; sleep 2; done; \
   argocd app list | cut -c 1-90
   ```

   In the interface, [the **Applications** page](:action:ui.applications) shows the platform with a sync status `Unknown` and a warning, and the shop and the blog beside it.

## The order is not what it seems

The waves of an app of apps order the creation of the Applications, and wait for the health of each wave before the next.
The health of an Application is not assessed by default: the documentation says the check "has been removed in argocd 1.8", and that it has to be restored "if you are using app-of-apps pattern and orchestrating synchronization using sync waves".
Without it, an Application counts as healthy the moment it exists, so a wave never waits.

1. Restore the check in `argocd-cm`.
   An Application is healthy when it is synced and its own health is: a new one is `Progressing` until its first sync, so the next wave waits for it:

   <!-- verify: expect="configmap/argocd-cm patched" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   tee health-patch.yaml <<EOT
   data:
     resource.customizations.health.argoproj.io_Application: |
       hs = {}
       hs.status = "Progressing"
       hs.message = ""
       if obj.status ~= nil and obj.status.health ~= nil and obj.status.sync ~= nil and obj.status.sync.status == "Synced" then
         hs.status = obj.status.health.status
         if obj.status.health.message ~= nil then hs.message = obj.status.health.message end
       end
       return hs
   EOT
   kubectl --namespace argocd patch configmap argocd-cm --type merge --patch-file health-patch.yaml
   ```

2. Start again, from the root: delete what the root made.
   The workloads stay, the Applications go:

   <!-- verify: timeout=120 expect="applications: 1" -->

   ```bash exec target=docker
   kubectl --namespace argocd delete applicationset apps > /dev/null && \
   kubectl --namespace argocd delete application platform --ignore-not-found > /dev/null && \
   for i in $(seq 1 30); do [ "$(kubectl --namespace argocd get applications --no-headers | wc -l)" = 1 ] && break; sleep 2; done; \
   echo "applications: $(kubectl --namespace argocd get applications --no-headers | wc -l)"
   ```

3. Sync the root again.
   It stops at the first wave, and says what it waits for:

   <!-- verify: timeout=120 expect="waiting for healthy state of argoproj.io/Application/platform" -->

   ```bash exec target=docker
   { timeout 60 argocd app sync root --timeout 20 || true; } 2>&1 | grep -E "^Message"
   ```

4. The ApplicationSet is not there, and the root is the only Application that is:

   <!-- verify: expect="applicationsets: 0" -->

   ```bash exec target=docker
   echo "applicationsets: $(kubectl --namespace argocd get applicationsets --no-headers 2> /dev/null | wc -l)"
   ```

5. Fix the typo, and push:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   sed -i 's#path: platfrom#path: platform#' bootstrap/platform.yaml && \
   git commit -q -am "Fix the path of the platform" && \
   git push 2>&1
   ```

6. The sync that waits is tied to the commit it started with.
   It is ended, and a new one reads the fixed layers, in order:
   the platform first, then the ApplicationSet and the Applications it makes:

   <!-- verify: timeout=180 expect="applications ready: 4" -->

   ```bash exec target=docker
   argocd app terminate-op root > /dev/null 2>&1; sleep 5; \
   for i in $(seq 1 20); do argocd app sync root > /dev/null 2>&1 && break; sleep 3; done; \
   for i in $(seq 1 60); do [ "$(kubectl --namespace argocd get applications --no-headers | grep -c 'Synced *Healthy')" = 4 ] && break; sleep 3; done; \
   echo "applications ready: $(kubectl --namespace argocd get applications --no-headers | grep -c 'Synced *Healthy')"
   ```

7. Read the four:

   <!-- verify: expect="argocd/platform" -->

   ```bash exec target=docker
   argocd app list | cut -c 1-80
   ```

   A new cluster needs the root only: the platform, then the applications, come from Git.

8. In the interface, [open the root](:action:ui.open-root): an Application is a node of the tree like any other resource, so the root shows the platform and the ApplicationSet, and the Applications that the ApplicationSet made hang under it.
   [The **ApplicationSets** page](:action:ui.applicationsets) lists the generator and the Applications it made, which is where to look when an application is missing.

## Argo CD managing itself

The documentation says Argo CD "is able to manage itself since all settings are represented by Kubernetes manifests".
An Application of the folder `bootstrap` can point to the manifests of Argo CD, a Kustomize base of the release or its Helm chart, so that an upgrade is a commit.
The version is pinned, as for any other layer.
