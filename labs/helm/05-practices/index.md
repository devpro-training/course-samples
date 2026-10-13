# Quality: lint, test and good practices

A chart is code, so it is checked like code: a linter reads it, a schema rejects bad values, a test runs against a real release, and a failed upgrade goes back by itself.
The chart of the previous step works, and this step makes it a chart that can be trusted.

## Lint

Two linters, for two questions.
`helm lint` asks whether the chart is a valid chart.
kube-linter asks whether the Kubernetes objects it renders are safe and complete.

1. Lint the chart as strictly as Helm can:

   <!-- verify: expect="0 chart(s) failed" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm lint --strict shop
   ```

2. Render the chart to a file, and read it with kube-linter.
   Each finding names a check and says how to fix it:

   <!-- verify: expect="lint errors" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm template dev shop > rendered.yaml && \
   { kube-linter lint rendered.yaml 2>&1 | grep -o 'check: [a-z-]*' ; kube-linter lint rendered.yaml 2>&1 | tail -1; }
   ```

## Fix what the linter found

The Deployment gets a security context, probes, labels from a helper, and the resources become a setting.
A helper is a named template, written once in `_helpers.tpl`, which the other templates include.
The chart version goes to 0.2.0, since the chart changed.

1. Write the helpers.
   The selector labels never change for a release, since a Deployment cannot change its selector:

   <!-- verify: expect="define: 2" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   tee templates/_helpers.tpl <<'EOT'
   {{- define "shop.selectorLabels" -}}
   app.kubernetes.io/name: shop
   app.kubernetes.io/instance: {{ .Release.Name }}
   {{- end }}

   {{- define "shop.labels" -}}
   helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
   {{ include "shop.selectorLabels" . }}
   app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
   app.kubernetes.io/managed-by: {{ .Release.Service }}
   {{- end }}
   EOT
   echo "define: $(grep -c 'define' templates/_helpers.tpl)"
   ```

2. Write the settings.
   The application listens on a port above 1024, so it runs as a user that is not root:

   <!-- verify: expect="settings: 6" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   tee values.yaml <<EOT
   # replicaCount is the number of Pods.
   replicaCount: 1

   image:
     # image.repository is the image of the application.
     repository: ${WHOAMI_IMAGE}
     # image.tag is its tag.
     tag: "${WHOAMI_TAG}"

   # message is the name the application prints in its answer.
   message: shop

   # port is the port the application listens on, above 1024 since it does not run as root.
   port: 8080

   # resources are the requests and limits of the container.
   resources:
     requests:
       cpu: 10m
       memory: 16Mi
     limits:
       cpu: 100m
       memory: 64Mi

   test:
     # test.image is the image of the Pod that \`helm test\` runs.
     image: ${BUSYBOX_IMAGE}
   EOT
   echo "settings: $(grep -c '^[a-z]' values.yaml)"
   ```

3. Write the Deployment and the Service again:

   <!-- verify: expect="templates: 3" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   tee templates/deployment.yaml <<'EOT'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: {{ .Release.Name }}-shop
     labels:
       {{- include "shop.labels" . | nindent 4 }}
   spec:
     replicas: {{ .Values.replicaCount }}
     selector:
       matchLabels:
         {{- include "shop.selectorLabels" . | nindent 6 }}
     template:
       metadata:
         labels:
           {{- include "shop.selectorLabels" . | nindent 8 }}
       spec:
         securityContext:
           runAsNonRoot: true
           runAsUser: 65532
           seccompProfile:
             type: RuntimeDefault
         containers:
           - name: shop
             image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
             env:
               - name: WHOAMI_NAME
                 value: {{ .Values.message | quote }}
               - name: WHOAMI_PORT_NUMBER
                 value: {{ .Values.port | quote }}
             ports:
               - name: http
                 containerPort: {{ .Values.port }}
             readinessProbe:
               httpGet:
                 path: /health
                 port: http
             livenessProbe:
               httpGet:
                 path: /health
                 port: http
             securityContext:
               allowPrivilegeEscalation: false
               readOnlyRootFilesystem: true
               capabilities:
                 drop:
                   - ALL
             resources:
               {{- toYaml .Values.resources | nindent 12 }}
   EOT
   tee templates/service.yaml <<'EOT'
   apiVersion: v1
   kind: Service
   metadata:
     name: {{ .Release.Name }}-shop
     labels:
       {{- include "shop.labels" . | nindent 4 }}
   spec:
     selector:
       {{- include "shop.selectorLabels" . | nindent 4 }}
     ports:
       - port: 80
         targetPort: http
   EOT
   sed -i 's/^version: .*/version: 0.2.0/' Chart.yaml && \
   echo "templates: $(ls templates | wc -l)"
   ```

4. Lint the new version.
   kube-linter has nothing left to say, and `echo` shows its exit status:

   <!-- verify: expect="status 0" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm lint --strict shop && \
   helm template dev shop > rendered.yaml && \
   kube-linter lint rendered.yaml; echo "status $?"
   ```

## Reject bad values

`values.schema.json` is a JSON Schema that Helm checks on install, upgrade, template and lint.
A wrong value stops at once, with a message, and does not reach the cluster.

1. Write the schema, and ask for zero Pods:

   <!-- verify: expect="don't meet" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   tee shop/values.schema.json <<'EOT'
   {
     "$schema": "https://json-schema.org/draft-07/schema#",
     "type": "object",
     "required": ["message"],
     "properties": {
       "replicaCount": { "type": "integer", "minimum": 1 },
       "port": { "type": "integer", "minimum": 1024, "maximum": 65535 },
       "message": { "type": "string", "minLength": 1 }
     }
   }
   EOT
   { helm template dev shop --set replicaCount=0 2>&1 || true; }
   ```

## Test a release

A chart test is a Pod with the annotation `helm.sh/hook: test`, which `helm test` creates in the release and which must exit with the status 0.
It checks the installed application from the inside of the cluster, with the Service name and not the address of a Pod.

1. Write the test.
   The Pod is deleted when it succeeds:

   <!-- verify: expect="tests: 1" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   mkdir -p templates/tests && \
   tee templates/tests/test-connection.yaml <<'EOT'
   apiVersion: v1
   kind: Pod
   metadata:
     name: {{ .Release.Name }}-shop-test
     labels:
       {{- include "shop.labels" . | nindent 4 }}
     annotations:
       "helm.sh/hook": test
       "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
   spec:
     restartPolicy: Never
     containers:
       - name: wget
         image: {{ .Values.test.image }}
         command: ["wget", "-qO-", "http://{{ .Release.Name }}-shop/"]
   EOT
   echo "tests: $(ls templates/tests | wc -l)"
   ```

2. Upgrade the release `dev` to the new version of the chart, and test it.
   `--logs` prints the output of the test Pod, which is what the application answered:

   <!-- verify: timeout=240 expect="Succeeded" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm upgrade dev shop --namespace shop --wait --timeout 3m && \
   helm test dev --namespace shop --logs --timeout 2m
   ```

## An upgrade that fails

An upgrade can fail after it was sent: an image that does not exist, a probe that never passes.
`--rollback-on-failure` makes Helm wait for the release to be ready, and go back to the last good revision when it is not.

1. Upgrade to an image tag that does not exist, and give Helm 45 seconds:

   <!-- verify: timeout=180 expect="UPGRADE FAILED" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   { helm upgrade dev shop --namespace shop --set image.tag=v0.0.0-nope --rollback-on-failure --timeout 45s 2>&1 || true; }
   ```

2. The history shows the failed revision and the return to the last good one.
   The application never stopped, since the Pod of the good revision was kept until the new one was ready:

   <!-- verify: expect="failed" -->

   ```bash exec target=docker
   helm history dev --namespace shop && \
   kubectl get pods --namespace shop --selector app.kubernetes.io/instance=dev
   ```

## Good practices

Practice                                   | Why
-------------------------------------------|---------------------------------------------------------------------------------------------------
Pin the chart version                      | `--version` in every command: a chart changes, and so does what it installs
Read before installing                     | `helm template`, `helm pull --untar`: a chart is a procedure that runs with the rights of the user
Keep `values.yaml` small                   | Flat, camelCase, every setting documented, and defaults that run
One file of values per environment         | `-f values-prod.yaml`, versioned in Git, never `--set` of a secret
Never put a secret in values               | They are stored in the release Secret, in clear in `helm get values`
Add a schema                               | Bad values stop before the cluster
Set the security context and the resources | A linter checks it, and a default that is safe is what most users keep
Never change a selector                    | A Deployment cannot, so the selector labels are a helper of their own
Test in CI                                 | `helm lint`, kube-linter, then `ct install` in a throwaway cluster
Bump `version` for every change            | A published version is never replaced
