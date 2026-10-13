# Projects and access

Until now every Application is in the project `default`, which may deploy any repository to any namespace of any cluster.
An `AppProject` is what makes Argo CD shared: it says which repositories a team may read, which clusters and namespaces it may write to, and which kinds of cluster-wide resources it may create.
Its roles and the RBAC of Argo CD say who may see and sync it.

## A project is a tenant

1. Declare the project of a team in the layers.
   The platform wave makes it before any Application that names it:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   tee bootstrap/team-a.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: AppProject
   metadata:
     name: team-a
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "0"
   spec:
     description: The first team, which may only deploy its own folder to its own namespace
     sourceRepos:
       - ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
     destinations:
       - server: https://kubernetes.default.svc
         namespace: team-a
     clusterResourceWhitelist:
       - group: ""
         kind: Namespace
   EOT
   git add . && git commit -q -m "Add the project of the first team" && git push 2>&1
   ```

2. Sync the root, and list the projects:

   <!-- verify: timeout=120 expect="projects: 2" -->

   ```bash exec target=docker
   argocd app sync root > /dev/null; \
   for i in $(seq 1 30); do [ "$(argocd proj list --output name 2> /dev/null | wc -l)" = 2 ] && break; sleep 2; done; \
   argocd proj list | cut -c 1-110; \
   echo "projects: $(argocd proj list --output name | wc -l)"
   ```

   Everything else is denied, by Argo CD: the cluster-wide resources outside `clusterResourceWhitelist`, the other namespaces, and the other repositories.
   In the interface, [**Settings**, then **Projects**](:action:ui.projects) lists them with their descriptions, and opening one shows its sources, destinations and roles.

3. An Application of the team asks for a namespace that is not its own.
   It is created, and it is invalid:

   <!-- verify: timeout=60 expect="conditions: 1" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   tee blog-team.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: blog-team
     namespace: argocd
   spec:
     project: team-a
     source:
       repoURL: ${GITEA_CLUSTER_URL}/${GITEA_ADMIN_USER}/deploy.git
       targetRevision: main
       path: apps/blog
     destination:
       server: https://kubernetes.default.svc
       namespace: shop
     syncPolicy:
       syncOptions:
         - CreateNamespace=true
   EOT
   kubectl apply -f blog-team.yaml > /dev/null && \
   for i in $(seq 1 20); do [ -n "$(kubectl --namespace argocd get application blog-team --output jsonpath='{.status.conditions[0].message}')" ] && break; sleep 2; done; \
   echo "conditions: $(kubectl --namespace argocd get application blog-team --output jsonpath='{.status.conditions[*].type}' | wc -w)" && \
   kubectl --namespace argocd get application blog-team --output jsonpath='{.status.conditions[0].message}{"\n"}'
   ```

4. Put it in the namespace of the team, and it syncs:

   <!-- verify: timeout=120 expect="pods of team-a: 2" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   sed -i 's/^    namespace: shop/    namespace: team-a/' blog-team.yaml && \
   kubectl apply -f blog-team.yaml > /dev/null && \
   for i in $(seq 1 20); do argocd app get blog-team --refresh 2> /dev/null | grep -q "^Sync Status: *OutOfSync" && break; sleep 2; done; \
   argocd app sync blog-team > /dev/null && \
   argocd app wait blog-team --health --timeout 100 > /dev/null; \
   echo "pods of team-a: $(kubectl --namespace team-a get pods --no-headers | wc -l)"
   ```

## A team account

The team does not get `admin`: it gets an account, and a role that is the project and nothing else.
Accounts are declared in `argocd-cm`, and the roles in `argocd-rbac-cm`, as resources of the namespace like the rest.

1. Declare the account of a developer, and give it a password.
   Only `admin` can, and the command asks for its password:

   <!-- verify: expect="Password updated" -->

   ```bash exec target=docker
   kubectl --namespace argocd patch configmap argocd-cm --type merge --patch '{"data":{"accounts.'"${DEV_USER}"'":"login"}}' > /dev/null && \
   argocd account update-password --account "${DEV_USER}" --current-password "${UI_ADMIN_PASSWORD}" --new-password "${DEV_PASSWORD}"
   ```

2. Give the role of the team to that account: read and sync, in its project, and nothing else:

   <!-- verify: expect="configmap/argocd-rbac-cm patched" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   tee rbac-patch.yaml <<EOT
   data:
     policy.csv: |
       p, role:team-a, applications, get, team-a/*, allow
       p, role:team-a, applications, sync, team-a/*, allow
       g, ${DEV_USER}, role:team-a
   EOT
   kubectl --namespace argocd patch configmap argocd-rbac-cm --type merge --patch-file rbac-patch.yaml
   ```

3. Log in as the developer, with a configuration file of its own so that the session of `admin` stays:

   <!-- verify: timeout=60 expect="logged in successfully" -->

   ```bash exec target=docker
   argocd --config ~/lab/argocd/dev-config login 127.0.0.1:${UI_PORT} --plaintext --username "${DEV_USER}" --password "${DEV_PASSWORD}"
   ```

4. The developer sees its own application and no other, can sync it, and is refused on the others:

   <!-- verify: timeout=60 expect="visible applications: 1" -->

   ```bash exec target=docker
   echo "visible applications: $(argocd --config ~/lab/argocd/dev-config app list --output name | wc -l)"
   ```

   <!-- verify: timeout=60 expect="refused: 1" -->

   ```bash exec target=docker
   echo "refused: $({ argocd --config ~/lab/argocd/dev-config app sync shop || true; } 2>&1 | grep -c 'permission denied')"
   ```

   The role is the least privilege that a team needs: it cannot delete its application, change its project, or read another one.

> [!NOTE]
> The lab keeps `admin`, which it needs to go on.
> A real installation sets `admin.enabled` to `"false"` in `argocd-cm` once SSO or the accounts exist, as the documentation says: the account that has the rights of everything is the one an attacker looks for.
> SSO replaces the local accounts: the groups of the identity provider are mapped to roles in `argocd-rbac-cm`, with `g, <group>, role:team-a`.
