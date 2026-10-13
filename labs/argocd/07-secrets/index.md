# Secrets

Everything Argo CD deploys comes from Git, and a Secret cannot be in Git as it is: a Secret file holds its value in base64, which is an encoding, and Git never forgets.
The documentation of Argo CD takes a side: fill the Secrets on the destination cluster, with a tool such as Sealed Secrets or External Secrets Operator, and "strongly caution against" injecting them while the manifests are rendered,
since Argo CD would then cache them in clear in Redis.
This step uses Sealed Secrets: the repository holds a ciphertext that only the controller of one cluster can open.

## The problem

1. Make the Secret file Kubernetes wants, without applying it, and read the value back from it:

   <!-- verify: expect="recovered: s3cr3t-lab-value" -->

   ```bash exec target=docker
   mkdir -p ~/lab/argocd && cd ~/lab/argocd && \
   kubectl create secret generic db --namespace shop --from-literal=password="${SHOP_DB_PASSWORD}" --dry-run=client --output yaml > db-plain.yaml && \
   echo "recovered: $(grep ' password:' db-plain.yaml | cut -d ' ' -f 4 | base64 -d)"
   ```

   Committed, this file would give the password to everyone who ever reads the repository, for ever.
   The file stays out of the repository, and is only the input of the next steps.

## The controller, delivered by the root

The controller is a Helm chart, and the `SealedSecret` of the shop is a custom resource whose definition comes from that chart:
the controller is a platform, so it goes in the first wave, and the applications in the second wave wait for its health, as in the previous step.
An Application can take a chart from a Helm repository with no repository declared, since the chart is public.

1. Add the Application of the controller to the layers, and push:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   tee bootstrap/sealed-secrets.yaml <<EOT
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: sealed-secrets
     namespace: argocd
     annotations:
       argocd.argoproj.io/sync-wave: "0"
   spec:
     project: default
     source:
       repoURL: ${SEALEDSECRETS_CHART_URL}
       chart: sealed-secrets
       targetRevision: ${SEALEDSECRETS_CHART_VERSION}
       helm:
         valuesObject:
           fullnameOverride: sealed-secrets-controller
     destination:
       server: https://kubernetes.default.svc
       namespace: sealed-secrets
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   EOT
   git add . && git commit -q -m "Add the Sealed Secrets controller to the platform" && git push 2>&1
   ```

2. Sync the root, and wait for the controller:

   <!-- verify: timeout=180 expect="controller pods: 1" -->

   ```bash exec target=docker
   argocd app sync root > /dev/null; \
   for i in $(seq 1 60); do argocd app get sealed-secrets 2> /dev/null | grep -q "Health Status: *Healthy" && break; sleep 3; done; \
   echo "controller pods: $(kubectl --namespace sealed-secrets get pods --no-headers | grep -c Running)"
   ```

3. Argo CD rendered the chart with `helm template` and applied the result, so Helm knows nothing of it.
   There is no release, and `helm list` would be empty:

   <!-- verify: expect="helm releases: 0" -->

   ```bash exec target=docker
   echo "helm releases: $(kubectl get secrets --all-namespaces --no-headers | grep -c sh.helm.release)"
   ```

## The command line

`kubeseal` reads the public certificate of the controller and encrypts a Secret for it.
It is a binary of its own, with the checksums of the release:

1. Download it, check it, and install it:

   <!-- verify: requires=network timeout=120 expect="kubeseal-0.40.0-linux-amd64.tar.gz: OK" -->

   ```bash exec target=docker
   cd ~/lab && \
   wget -q "${SEALEDSECRETS_URL}/v${SEALEDSECRETS_VERSION}/kubeseal-${SEALEDSECRETS_VERSION}-linux-amd64.tar.gz" "${SEALEDSECRETS_URL}/v${SEALEDSECRETS_VERSION}/sealed-secrets_${SEALEDSECRETS_VERSION}_checksums.txt" && \
   grep " kubeseal-${SEALEDSECRETS_VERSION}-linux-amd64.tar.gz$" "sealed-secrets_${SEALEDSECRETS_VERSION}_checksums.txt" | sha256sum --check && \
   tar -xzf "kubeseal-${SEALEDSECRETS_VERSION}-linux-amd64.tar.gz" kubeseal && \
   install -m 0755 kubeseal /usr/local/bin/kubeseal
   ```

## Seal it

1. Encrypt the Secret for the cluster, into the folder of the shop.
   The result is a `SealedSecret`, and the password is not in it:

   <!-- verify: expect="clear text in the file: 0" -->

   ```bash exec target=docker
   cd ~/lab/argocd && \
   kubeseal --controller-name sealed-secrets-controller --controller-namespace sealed-secrets --format yaml < db-plain.yaml > deploy/apps/shop/db-sealed.yaml && \
   head -9 deploy/apps/shop/db-sealed.yaml | cut -c 1-70 && \
   echo "clear text in the file: $(grep -c "${SHOP_DB_PASSWORD}" deploy/apps/shop/db-sealed.yaml)"
   ```

2. Commit it.
   This file is safe in the repository, and a pull request on it shows a Secret that changed, and nothing else:

   <!-- verify: timeout=60 expect="main -> main" -->

   ```bash exec target=docker
   cd ~/lab/argocd/deploy && \
   git add . && git commit -q -m "Add the database password of the shop, sealed" && git push 2>&1
   ```

3. Argo CD syncs the shop, and the controller turns the `SealedSecret` into the Secret:

   <!-- verify: timeout=120 expect="secret in the cluster: s3cr3t-lab-value" -->

   ```bash exec target=docker
   for i in $(seq 1 40); do argocd app get shop --refresh > /dev/null; kubectl --namespace shop get secret db > /dev/null 2>&1 && break; sleep 3; done; \
   echo "secret in the cluster: $(kubectl --namespace shop get secret db --output jsonpath='{.data.password}' | base64 -d)"
   ```

4. The Secret is not in Git, and Argo CD did not create it: the controller did, and owns it.
   Argo CD sees the `SealedSecret` of the repository and leaves its child alone, so a prune never touches it:

   <!-- verify: expect="owner: SealedSecret" -->

   ```bash exec target=docker
   echo "owner: $(kubectl --namespace shop get secret db --output jsonpath='{.metadata.ownerReferences[0].kind}')"
   ```

   In the interface, [open the shop](:action:ui.open-shop): the `SealedSecret` is a node of the tree, and the Secret hangs under it.
   Click it: the panel shows the keys and not the values.

## The key is the cluster

A `SealedSecret` is encrypted for one controller, with a key that the controller made at its first start and keeps in a Secret of its namespace.
A cluster that has another key cannot open it, and a cluster that loses the key cannot open any of them:

1. Count the keys, and read the name of the Secret to back up:

   <!-- verify: expect="private keys: 1" -->

   ```bash exec target=docker
   echo "private keys: $(kubectl --namespace sealed-secrets get secrets --selector sealedsecrets.bitnami.com/sealed-secrets-key --no-headers | wc -l)"
   ```

   The backup of that Secret, outside of the cluster and of Git, is the recovery of every sealed Secret of the cluster.
   With many clusters, there is one key per cluster, and each file of Git is sealed for the cluster it goes to: the slides of the introduction show how the repository is organized for it.
