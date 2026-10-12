# Deployments

A Deployment keeps a number of identical Pods running, and replaces them step by step when the template changes.
It does not own the Pods itself: it creates a ReplicaSet for each version of the template, and the ReplicaSet creates the Pods.

## Three replicas

1. Write the manifest.
   `selector` says which Pods the Deployment owns, and `template` is the Pod it creates, so the labels of the template must match the selector:

   ```bash exec target=kube
   mkdir -p ~/lab/deploy && cd ~/lab/deploy && \
   tee deploy.yaml <<EOT
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: web
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: web
     template:
       metadata:
         labels:
           app: web
       spec:
         containers:
           - name: nginx
             image: ${NGINX_IMAGE}
             ports:
               - containerPort: 80
   EOT
   ```

2. Apply it, and wait for the rollout:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=kube
   cd ~/lab/deploy && kubectl apply -f deploy.yaml && \
   kubectl rollout status deployment/web --timeout=200s
   ```

3. The three levels: the Deployment, its ReplicaSet and the Pods, whose names carry the name of the ReplicaSet:

   <!-- verify: expect="replicaset.apps/web-" -->

   ```bash exec target=kube
   kubectl get deployment,replicaset,pods --selector app=web
   ```

## Self-healing

1. Delete one Pod.
   The ReplicaSet sees two Pods where three are desired, and creates one:

   ```bash exec target=kube
   kubectl delete "$(kubectl get pods --selector app=web -o name | head -n 1)"
   ```

2. Wait for the new Pod, and count the ready ones:

   <!-- verify: timeout=120 expect="3/3" -->

   ```bash exec target=kube
   kubectl wait --for=condition=Ready pod --selector app=web --timeout=100s > /dev/null && \
   kubectl get deployment web
   ```

## Scale

1. Ask for five replicas, and wait:

   <!-- verify: timeout=120 expect="5/5" -->

   ```bash exec target=kube
   kubectl scale deployment web --replicas=5 && \
   kubectl rollout status deployment/web --timeout=100s && \
   kubectl get deployment web
   ```

2. The file still says three.
   Applying it again moves the cluster back to what the file declares, which is why the file is the source of truth and the command above is an exception:

   <!-- verify: expect="configured" -->

   ```bash exec target=kube
   cd ~/lab/deploy && kubectl apply -f deploy.yaml
   ```

## A rolling update

1. Change the image in the file, and apply it:

   <!-- verify: requires=network timeout=240 expect="successfully rolled out" -->

   ```bash exec target=kube
   cd ~/lab/deploy && \
   sed -i "s|${NGINX_IMAGE}|${NGINX_NEXT_IMAGE}|" deploy.yaml && \
   kubectl apply -f deploy.yaml && \
   kubectl rollout status deployment/web --timeout=200s
   ```

   The Deployment started Pods of the new version, and stopped the old ones as the new became ready, so the service never went down.

2. A second ReplicaSet now holds the three Pods, and the first one is kept at zero, with its template:

   <!-- verify: expect="DESIRED" -->

   ```bash exec target=kube
   kubectl get replicasets --selector app=web
   ```

3. The image the Pods run:

   <!-- verify: expect="nginx:1.31" -->

   ```bash exec target=kube
   kubectl get pods --selector app=web -o jsonpath='{.items[*].spec.containers[*].image}{"\n"}'
   ```

## A rollback

1. The revisions are kept, so the previous one comes back with one command:

   <!-- verify: expect="REVISION" -->

   ```bash exec target=kube
   kubectl rollout history deployment/web
   ```

   <!-- verify: timeout=240 expect="rolled back" -->

   ```bash exec target=kube
   kubectl rollout undo deployment/web && \
   kubectl rollout status deployment/web --timeout=200s
   ```

   <!-- verify: expect="nginx:1.30" -->

   ```bash exec target=kube
   kubectl get pods --selector app=web -o jsonpath='{.items[*].spec.containers[*].image}{"\n"}'
   ```
