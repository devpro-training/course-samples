# Configuration

An image is the same in every environment, and what changes goes in the cluster: a ConfigMap for settings, a Secret for credentials.
A Pod receives them as environment variables or as files.

## A ConfigMap and a Secret

1. Write a ConfigMap with a setting and a web page, and create a Secret from a literal:

   ```bash exec target=kube
   mkdir -p ~/lab/config && cd ~/lab/config && \
   tee configmap.yaml <<EOT
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: greeting
   data:
     GREETING: Hello from a ConfigMap
     index.html: "<h1>Hello from a ConfigMap</h1>"
   EOT
   kubectl apply -f configmap.yaml && \
   kubectl create secret generic db --from-literal=PASSWORD=s3cr3t-pass
   ```

2. A Pod that reads both.
   `env` takes one key of each as an environment variable, and `volumes` mounts the ConfigMap as a folder, where each key is a file:

   <!-- verify: requires=network timeout=240 expect="condition met" -->

   ```bash exec target=kube
   cd ~/lab/config && \
   tee pod.yaml <<EOT
   apiVersion: v1
   kind: Pod
   metadata:
     name: config-demo
   spec:
     containers:
       - name: nginx
         image: ${NGINX_IMAGE}
         env:
           - name: GREETING
             valueFrom:
               configMapKeyRef:
                 name: greeting
                 key: GREETING
           - name: PASSWORD
             valueFrom:
               secretKeyRef:
                 name: db
                 key: PASSWORD
         volumeMounts:
           - name: html
             mountPath: /usr/share/nginx/html
     volumes:
       - name: html
         configMap:
           name: greeting
           items:
             - key: index.html
               path: index.html
   EOT
   kubectl apply -f pod.yaml && \
   kubectl wait --for=condition=Ready pod/config-demo --timeout=200s
   ```

3. The environment of the container, and the page it serves:

   <!-- verify: expect="s3cr3t-pass" -->

   ```bash exec target=kube
   kubectl exec config-demo -- printenv GREETING PASSWORD
   ```

   <!-- verify: timeout=60 expect="<h1>Hello from a ConfigMap</h1>" -->

   ```bash exec target=kube
   for i in $(seq 1 10); do kubectl exec config-demo -- wget -qO- http://127.0.0.1 && break; sleep 1; done
   ```

## What a Secret protects

1. A Secret is stored encoded in base64, which is not encryption:

   <!-- verify: expect="czNjcjN0LXBhc3M=" -->

   ```bash exec target=kube
   kubectl get secret db -o jsonpath='{.data.PASSWORD}{"\n"}'
   ```

   <!-- verify: expect="s3cr3t-pass" -->

   ```bash exec target=kube
   kubectl get secret db -o jsonpath='{.data.PASSWORD}' | base64 -d; echo
   ```

2. It is stored as it is in the datastore.
   The file of the previous step holds the value, readable by whoever can read the file:

   <!-- verify: expect="file: True" -->

   ```bash exec target=kube
   python3 - <<'EOT'
   import sqlite3
   db = sqlite3.connect("file:/var/lib/rancher/k3s/server/db/state.db?mode=ro", uri=True)
   value = db.execute("select value from kine where name = '/registry/secrets/default/db' order by id desc limit 1").fetchone()[0]
   print("readable in the datastore file:", b"s3cr3t-pass" in value)
   EOT
   ```

   The Kubernetes documentation says it: Secrets are by default stored unencrypted in the datastore, and anyone with access to the API or to the datastore can read them.
   The precautions are encryption at rest, which k3s enables with `--secrets-encryption`, RBAC rules that limit who can read a Secret, and an external secret store.

   Reference: [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/), [k3s secrets encryption](https://docs.k3s.io/cli/secrets-encrypt).
