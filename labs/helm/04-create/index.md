# Create a chart

A chart is a folder.
It holds a `Chart.yaml` that names it, YAML files in `templates/`, and a `values.yaml` of defaults.
The chart of this step packages `whoami`, a web server that prints the request it receives, and starts with plain manifests: a chart that has no template at all is already a chart.

## A chart with no template

1. Write the description of the chart.
   `version` is the version of the chart, `appVersion` the one of the application inside it, and they change independently:

   <!-- verify: expect="files: 2" -->

   ```bash exec target=docker
   mkdir -p ~/lab/charts/shop/templates && cd ~/lab/charts/shop && \
   tee Chart.yaml <<EOT
   apiVersion: v2
   name: shop
   description: A small web application that prints the request it receives
   type: application
   version: 0.1.0
   appVersion: "${WHOAMI_TAG}"
   EOT
   echo "files: $(ls | wc -l)"
   ```

2. Add the two manifests as they would be written for `kubectl apply`:

   <!-- verify: expect="templates: 2" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   tee templates/deployment.yaml <<EOT
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
             image: ${WHOAMI_IMAGE}:${WHOAMI_TAG}
             env:
               - name: WHOAMI_NAME
                 value: shop
   EOT
   tee templates/service.yaml <<EOT
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
   echo "templates: $(ls templates | wc -l)"
   ```

3. Check the chart, then render it.
   `helm lint` reads the folder, `helm template` prints what would be sent to the cluster, and needs no cluster:

   <!-- verify: expect="0 chart(s) failed" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm lint shop && \
   helm template shop | head -12
   ```

## Values

Two releases of this chart would collide, since the names are fixed.
A template is a YAML file with `{{ ... }}` actions, and Helm gives them objects: `.Release` for the installation, `.Chart` for `Chart.yaml`, and `.Values` for the settings.

1. List the settings, and their defaults, in `values.yaml`.
   Each one is documented, starting with its name:

   <!-- verify: expect="settings: 3" -->

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
   EOT
   echo "settings: $(grep -c '^[a-z]' values.yaml)"
   ```

2. Turn the manifests into templates.
   The name of a resource starts with the name of the release, so each release owns its objects, and the settings replace the values that were fixed:

   <!-- verify: expect="templates: 2" -->

   ```bash exec target=docker
   cd ~/lab/charts/shop && \
   tee templates/deployment.yaml <<'EOT'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: {{ .Release.Name }}-shop
   spec:
     replicas: {{ .Values.replicaCount }}
     selector:
       matchLabels:
         app.kubernetes.io/name: shop
         app.kubernetes.io/instance: {{ .Release.Name }}
     template:
       metadata:
         labels:
           app.kubernetes.io/name: shop
           app.kubernetes.io/instance: {{ .Release.Name }}
       spec:
         containers:
           - name: shop
             image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
             env:
               - name: WHOAMI_NAME
                 value: {{ .Values.message | quote }}
   EOT
   tee templates/service.yaml <<'EOT'
   apiVersion: v1
   kind: Service
   metadata:
     name: {{ .Release.Name }}-shop
   spec:
     selector:
       app.kubernetes.io/name: shop
       app.kubernetes.io/instance: {{ .Release.Name }}
     ports:
       - port: 80
   EOT
   echo "templates: $(ls templates | wc -l)"
   ```

3. Render the chart as two releases, with a different value for the second.
   `--set` overrides one setting, `--show-only` prints one template:

   <!-- verify: expect="name: prod-shop" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm template dev shop --show-only templates/service.yaml && \
   helm template prod shop --set replicaCount=3 --show-only templates/deployment.yaml | head -8
   ```

## One chart, many environments

A file of values holds what differs between environments, and the chart stays the same.

1. Write the values of production.
   Only what differs is written, the rest comes from the defaults of the chart:

   <!-- verify: expect="environments: 1" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   tee values-prod.yaml <<EOT
   replicaCount: 3
   message: shop in production
   EOT
   echo "environments: $(ls values-*.yaml | wc -l)"
   ```

2. Install the chart twice, in the same namespace.
   `-f` reads a file of values, and the release names keep the objects apart:

   <!-- verify: timeout=240 expect="prod-shop" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm install dev shop --namespace shop --create-namespace --wait --timeout 3m && \
   helm install prod shop --namespace shop -f values-prod.yaml --wait --timeout 3m && \
   kubectl get deployment --namespace shop
   ```

3. Each Pod got the setting of its release:

   <!-- verify: expect="shop in production" -->

   ```bash exec target=docker
   for r in dev prod; do echo "$r: $(kubectl get deployment ${r}-shop --namespace shop -o jsonpath='{.spec.template.spec.containers[0].env[0].value}')"; done
   ```

## Package

1. Package the chart.
   The archive is named after the name and the version of the chart, and is what a repository stores:

   <!-- verify: expect="Successfully packaged" -->

   ```bash exec target=docker
   cd ~/lab/charts && \
   helm package shop && \
   tar -tzf shop-0.1.0.tgz
   ```
