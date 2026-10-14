# Tenants

By default Flux applies everything with the rights of its controller, which are those of a cluster administrator.
A team that can push to a folder of the repository would then do whatever an administrator does.
A `Kustomization` can name a ServiceAccount instead, and the controller impersonates it: the team then does what its account is allowed to do, and nothing else.

## The platform side

1. Ask `flux` for a tenant, as the platform team would.
   It writes a namespace, a ServiceAccount and a RoleBinding, and `--cluster-role admin` limits the account to what the built-in role `admin` allows in that namespace, instead of `cluster-admin`.
   Then the `Kustomization` of the tenant, which names the account.
   It lives in the namespace of the tenant and reads the source of the platform, `flux-system.flux-system` being the name and the namespace of the `GitRepository`:

   <!-- verify: expect="serviceAccountName: team-a" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   flux create tenant team-a --with-namespace team-a --cluster-role admin --export > clusters/hub/team-a.yaml && \
   echo "---" >> clusters/hub/team-a.yaml && \
   flux create kustomization team-a --namespace team-a --source GitRepository/flux-system.flux-system --path ./tenants/team-a --prune true --interval 1m \
     --service-account team-a --target-namespace team-a --export >> clusters/hub/team-a.yaml && \
   grep -E "serviceAccountName|kind: (Namespace|ServiceAccount|RoleBinding|Kustomization)" clusters/hub/team-a.yaml
   ```

## The tenant side

1. The team owns a folder, `tenants/team-a`, and puts a Deployment in it, and also a `ClusterRole`, which is a cluster wide object the team has no right to create:

   <!-- verify: expect="tenants/team-a/kustomization.yaml" -->

   ```bash exec target=docker
   mkdir -p ~/lab/fleet/tenants/team-a && cd ~/lab/fleet/tenants/team-a && \
   cat > deployment.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: site
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: site
     template:
       metadata:
         labels:
           app: site
       spec:
         containers:
           - name: web
             image: ${WHOAMI_IMAGE}
   EOT
   cat > clusterrole.yaml <<EOT
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: read-everything
   rules:
     - apiGroups: ["*"]
       resources: ["*"]
       verbs: ["get", "list"]
   EOT
   cat > kustomization.yaml <<EOT
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   resources:
     - deployment.yaml
     - clusterrole.yaml
   EOT
   cd ~/lab/fleet && find tenants -type f | sort
   ```

2. Commit it, and look at what Flux says:

   <!-- verify: timeout=180 expect="is forbidden" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Add the tenant team-a" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 40); do kubectl --namespace team-a get kustomization team-a > /dev/null 2>&1 && break; sleep 3; done; \
   flux reconcile kustomization team-a --namespace team-a --timeout 30s > /dev/null 2>&1 ; \
   kubectl --namespace team-a get kustomization team-a --output jsonpath='{.status.conditions[?(@.type=="Ready")].message}' | tr '\n' ' ' | cut -c 1-400
   ```

   The error names the account: `system:serviceaccount:team-a:team-a`.
   It is the Kubernetes API that refuses, with its own RBAC, so no rule of Flux has to be written.

3. The Deployment is allowed, and was not applied either.
   Flux checks the whole set with a dry run first, so one refused object stops the others:

   <!-- verify: expect="deployments of team-a: 0" -->

   ```bash exec target=docker
   echo "deployments of team-a: $(kubectl --namespace team-a get deployments --no-headers 2> /dev/null | wc -l)"
   ```

4. Remove the cluster wide object, and the same Kustomization goes green, with the same account:

   <!-- verify: timeout=180 expect="deployments after the fix: 1" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git rm -q tenants/team-a/clusterrole.yaml && sed -i '/clusterrole.yaml/d' tenants/team-a/kustomization.yaml && \
   git commit -q -am "Remove the cluster role from the tenant" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   flux reconcile kustomization team-a --namespace team-a --with-source --timeout 60s > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do kubectl --namespace team-a get deployment site > /dev/null 2>&1 && break; sleep 2; done; \
   echo "deployments after the fix: $(kubectl --namespace team-a get deployments --no-headers | wc -l)"
   ```

5. The account is what the controller used, and the target namespace is forced on every namespaced object, so a manifest cannot name another namespace to escape:

   <!-- verify: expect="namespace of the Deployment: team-a" -->

   ```bash exec target=docker
   echo "namespace of the Deployment: $(kubectl get deployments --all-namespaces --no-headers | grep ' site ' | cut -d ' ' -f 1)"
   ```

## The controller can enforce it

A tenant that forgets `serviceAccountName` would be applied with the rights of the controller.
The controllers have flags that close that door, which the lab does not set, since its own `Kustomizations` (`infra`, `shop`) would then need an account too:

Flag                                 | Controllers                          | Effect
-------------------------------------|--------------------------------------|---------------------------------------------------------------
`--default-service-account=<name>`   | `kustomize-controller`, `helm-controller` | An object with no `serviceAccountName` uses this account of its namespace
`--no-cross-namespace-refs=true`     | All controllers                      | An object cannot use a source or a dependency of another namespace
`--no-remote-bases=true`             | `kustomize-controller`               | A `kustomization.yaml` cannot load a base from a URL

- They are added to the controller Deployments by a patch in the `kustomization.yaml` of `clusters/<name>/flux-system`, which `flux bootstrap` keeps when it is run again.
- The `Kustomization` `flux-system` itself names `serviceAccountName: kustomize-controller`, which is `cluster-admin`, so the platform keeps its rights.
- Reference: [Flux multi-tenancy configuration](https://fluxcd.io/flux/installation/configuration/multitenancy/).
