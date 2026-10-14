# Helm

Flux installs a chart with two objects: a `HelmRepository` that says where the charts are, and a `HelmRelease` that says which chart, which version and which values.
The Helm controller runs the Helm library in the cluster, and the command `helm` is not needed.

## The source and the release

The files go in `clusters/hub`, the folder the bootstrap follows: the `Kustomization` `flux-system` of the previous step applies whatever is committed there, `HelmRelease` files included.
The next step looks at that object itself.

1. Write the repository object with `flux`, in a file of its own, and the release by hand in a folder of its own, since its values are the part that matters.
   One file per repository and one folder per release keep a diff and a review readable, whatever the number of charts.
   The chart is `podinfo`, a small web application of the maintainer of Flux, pinned to a version:

   <!-- verify: expect="chart lines: 1" -->

   ```bash exec target=docker
   cd ~/lab/fleet && mkdir -p clusters/hub/helmrepositories clusters/hub/podinfo && \
   flux create source helm podinfo --url "${PODINFO_CHART_URL}" --interval 1h --export > clusters/hub/helmrepositories/podinfo.yaml && \
   cat > clusters/hub/podinfo/helmrelease.yaml <<EOT
   apiVersion: helm.toolkit.fluxcd.io/v2
   kind: HelmRelease
   metadata:
     name: podinfo
     namespace: flux-system
   spec:
     interval: 10m
     releaseName: podinfo
     targetNamespace: podinfo
     chart:
       spec:
         chart: podinfo
         version: "${PODINFO_CHART_VERSION}"
         sourceRef:
           kind: HelmRepository
           name: podinfo
           namespace: flux-system
     install:
       createNamespace: true
     # https://github.com/stefanprodan/podinfo/blob/master/charts/podinfo/values.yaml
     values:
       replicaCount: 1
   EOT
   echo "chart lines: $(grep -c 'chart: podinfo' clusters/hub/podinfo/helmrelease.yaml)"
   ```

   - **`releaseName` and `targetNamespace`** are set, since Helm would otherwise name the release `<targetNamespace>-<name>`.
   - **`createNamespace`** lets Helm make the namespace of the release.
   - **`sourceRef.namespace`** names the namespace of the repository object, which is explicit when the release is in another one.
   - **`interval`** is how often the release is compared with its chart, and the repository object has its own, longer, one.

2. Commit, and let Flux apply it:

   <!-- verify: requires=network timeout=240 expect="podinfo release: True" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Install podinfo with Helm" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do kubectl --namespace flux-system get helmrelease podinfo > /dev/null 2>&1 && break; sleep 2; done; \
   kubectl --namespace flux-system wait helmrelease podinfo --for=condition=Ready --timeout=180s > /dev/null 2>&1 ; \
   echo "podinfo release: $(kubectl --namespace flux-system get helmrelease podinfo --output jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
   ```

3. The state, as `flux` shows it:

   <!-- verify: expect="Helm install succeeded" -->

   ```bash exec target=docker
   flux get helmreleases
   ```

4. Flux fetched the chart itself, as an artifact of the source controller.
   The release is a Helm release like any other, and Helm keeps its record, one Secret per revision, in the namespace of the `HelmRelease` object (`storageNamespace` changes it):

   <!-- verify: expect="sh.helm.release.v1.podinfo.v1" -->

   ```bash exec target=docker
   flux get sources chart && kubectl --namespace flux-system get secrets
   ```

## A change of values

1. Two replicas, in Git:

   <!-- verify: expect="replicaCount in the file: 2" -->

   ```bash exec target=docker
   cd ~/lab/fleet && sed -i 's/replicaCount: 1/replicaCount: 2/' clusters/hub/podinfo/helmrelease.yaml && \
   git commit -q -am "Run two replicas of podinfo" && git push -q && \
   echo "replicaCount in the file: $(grep -o 'replicaCount: [0-9]*' clusters/hub/podinfo/helmrelease.yaml | cut -d ' ' -f 2)"
   ```

2. The release is upgraded, and Helm keeps a second revision:

   <!-- verify: timeout=240 expect="upgrade succeeded" -->

   ```bash exec target=docker
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 60); do kubectl --namespace flux-system get secret sh.helm.release.v1.podinfo.v2 > /dev/null 2>&1 && break; sleep 2; done; \
   flux reconcile helmrelease podinfo > /dev/null 2>&1 ; \
   flux get helmrelease podinfo | tail -1 | cut -f 5 | cut -c 1-120
   ```

## Drift of a release

1. A hand change of the Pods count is not undone by default, since Flux compares a Helm release with its own revision and not with the cluster:

   <!-- verify: timeout=60 expect="replicas after the reconcile: 4" -->

   ```bash exec target=docker
   kubectl --namespace podinfo scale deployment podinfo --replicas 4 > /dev/null && \
   flux reconcile helmrelease podinfo > /dev/null 2>&1 ; \
   echo "replicas after the reconcile: $(kubectl --namespace podinfo get deployment podinfo --output jsonpath='{.spec.replicas}')"
   ```

2. `driftDetection` makes the controller compare the release with the cluster, and correct it:

   <!-- verify: expect="driftDetection in the file: enabled" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   sed -i 's/^  install:/  driftDetection:\n    mode: enabled\n  install:/' clusters/hub/podinfo/helmrelease.yaml && \
   git commit -q -am "Detect the drift of podinfo" && git push -q && \
   echo "driftDetection in the file: $(grep -A1 driftDetection clusters/hub/podinfo/helmrelease.yaml | grep -o 'enabled')"
   ```

3. After the next reconciliation, Git wins:

   <!-- verify: timeout=180 expect="replicas with drift detection: 2" -->

   ```bash exec target=docker
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do kubectl --namespace flux-system get helmrelease podinfo --output yaml | grep -q "mode: enabled" && break; sleep 2; done; \
   flux reconcile helmrelease podinfo > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do [ "$(kubectl --namespace podinfo get deployment podinfo --output jsonpath='{.spec.replicas}')" = 2 ] && break; sleep 2; done; \
   echo "replicas with drift detection: $(kubectl --namespace podinfo get deployment podinfo --output jsonpath='{.spec.replicas}')"
   ```
