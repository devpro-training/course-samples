# Sync policy

By default Argo CD only reports: it says what differs and waits to be told to sync.
The sync policy of an application is how much of that it does by itself, and each option has a default that is worth knowing.

## Drift is reported

1. Change the cluster by hand, to 5 replicas, and ask Argo CD to look:

   <!-- verify: timeout=60 expect="OutOfSync from" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 5 > /dev/null && \
   sleep 2 && \
   argocd app get shop --refresh | grep -E "^Sync Status"
   ```

2. The application is `OutOfSync`, and nothing was corrected.
   The diff is the line that the cluster holds and Git does not:

   <!-- verify: expect="replicas: 5" -->

   ```bash exec target=docker
   { argocd app diff shop || true; } | grep -E "^[<>] +replicas"
   ```

   In the interface, the Deployment of the tree carries the **OutOfSync** mark, and **DIFF** shows the same lines.

## Automated sync and self-heal

1. Declare the policy in the application: a sync when the repository changes, and when the cluster drifts:

   <!-- verify: expect="application.argoproj.io/shop configured" -->

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
       automated:
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   EOT
   kubectl apply -f shop-application.yaml
   ```

2. The cluster goes back to the repository, with no command:

   <!-- verify: timeout=90 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

3. Change it by hand again, to 4.
   The self-heal acts within seconds, since the controller watches the resources of its applications, and does not wait for the 3 minutes of the repository:

   <!-- verify: timeout=60 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 4 > /dev/null; \
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 1; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

## Prune is off by default

The documentation says an automated sync "will not delete resources when Argo CD detects the resource is no longer defined in Git".
Deleting is the one action that cannot be undone by a sync, so it is an option of its own.

1. Add a second Service to the repository.
   The automated sync creates it after the next look at the repository:

   <!-- verify: timeout=120 expect="services: 2" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
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
   git add . && git commit -q -m "Add a second Service" && git push -q && \
   for i in $(seq 1 30); do argocd app get shop --refresh > /dev/null; kubectl --namespace shop get service extra > /dev/null 2>&1 && break; sleep 2; done; \
   echo "services: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```

2. Remove its file, and look again:

   <!-- verify: timeout=60 expect="services still there: 2" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   git rm -q apps/shop/extra-service.yaml && \
   git commit -q -m "Remove the second Service" && git push -q && \
   argocd app get shop --refresh | grep -E "^Sync Status" ; sleep 5; \
   echo "services still there: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```

   The application is `OutOfSync`, and the Service stays.
   In the interface, the application is **OutOfSync** and the Service is still in the tree.

3. Turn the pruning on, in the policy.
   A change of policy is seen at the next look at the repository, which a refresh asks for, and the Service goes:

   <!-- verify: timeout=90 expect="services: 1" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   sed -i 's/^      selfHeal: true/      prune: true\n      selfHeal: true/' shop-application.yaml && \
   kubectl apply -f shop-application.yaml > /dev/null && \
   for i in $(seq 1 30); do argocd app get shop --refresh > /dev/null; kubectl --namespace shop get service extra > /dev/null 2>&1 || break; sleep 2; done; \
   echo "services: $(kubectl --namespace shop get services --no-headers | wc -l)"
   ```

## What Git does not own

Some fields belong to another controller: the replicas of a Deployment that a HorizontalPodAutoscaler scales, a certificate that a webhook injects.
Argo CD would call each of them a drift, and a self-heal would fight the controller forever.
`ignoreDifferences` tells it which fields to leave alone, by JSON pointer, by `jq` path, or by the manager that owns them.

1. Ignore the replicas of the Deployments of the shop:

   <!-- verify: expect="application.argoproj.io/shop patched" -->

   ```bash exec target=docker
   kubectl --namespace argocd patch application shop --type merge \
     --patch '{"spec":{"ignoreDifferences":[{"group":"apps","kind":"Deployment","jsonPointers":["/spec/replicas"]}]}}'
   ```

2. Scale by hand, to 3.
   The self-heal does nothing, and the application stays `Synced`: the field is not part of the comparison anymore:

   <!-- verify: timeout=60 expect="replicas in the cluster: 3" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 3 > /dev/null; sleep 8; \
   argocd app get shop --refresh | grep -E "^Sync Status"; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

3. Remove the rule, and the field is Git's again:

   <!-- verify: timeout=90 expect="replicas in the cluster: 2" -->

   ```bash exec target=docker
   kubectl --namespace argocd patch application shop --type json --patch '[{"op":"remove","path":"/spec/ignoreDifferences"}]' > /dev/null && \
   for i in $(seq 1 30); do [ "$(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

   An ignored field is a decision to write down: the rule is in the Application, so it is in Git too once the Applications are.

## Rollback is refused

The documentation says a rollback "cannot be performed against an application with automated sync enabled": the controller would put the cluster back to the repository at once.

1. Try it:

   <!-- verify: expect="refusals: 1" -->

   ```bash exec target=docker
   echo "refusals: $({ argocd app rollback shop 0 || true; } 2>&1 | grep -c 'rollback cannot be initiated')"
   ```

   The way back is a commit that reverts the change, which is also the audit trail.

## What the loop does not do

- **A failed sync is not tried again** for the same commit, unless the application has a `retry` policy.
- **A deleted Application keeps its resources**, unless it carries the finalizer `resources-finalizer.argocd.argoproj.io`: the cascade is an option too.
- **A new commit is seen within 3 minutes**, and at once with a webhook from the Git server.
