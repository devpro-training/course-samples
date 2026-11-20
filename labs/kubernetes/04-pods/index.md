# Pods

A Pod is the smallest object Kubernetes runs: one or more containers that share a network address and their volumes.
An object is written as a manifest, a YAML file that `kubectl apply` sends to the API.

## A manifest

1. Write the manifest of a Pod that runs nginx:

   ```bash exec target=kube
   mkdir -p ~/lab/pods && cd ~/lab/pods && \
   tee web.yaml <<EOT
   apiVersion: v1
   kind: Pod
   metadata:
     name: web
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

   Field        | Says
   -------------|-------------------------------------------------------
   `apiVersion` | The group and version of the API that defines the kind
   `kind`       | The kind of object
   `metadata`   | Its name, in a namespace, and its labels
   `spec`       | The desired state: here the containers of the Pod

## Apply

1. Send it to the API.
   The API server stores the object in the datastore, and nothing runs yet:

   <!-- verify: expect="pod/web created" -->

   ```bash exec target=kube
   cd ~/lab/pods && kubectl apply -f web.yaml
   ```

2. Wait until the Pod is ready.
   The scheduler chose the node, and the kubelet pulled the image and started the container:

   <!-- verify: requires=network timeout=240 expect="condition met" -->

   ```bash exec target=kube
   kubectl wait --for=condition=Ready pod/web --timeout=200s
   ```

3. The events say what each component did:

   <!-- verify: expect="Successfully assigned" -->

   ```bash exec target=kube
   kubectl describe pod web | grep -A 8 "^Events"
   ```

4. The object now holds what the cluster added to the spec: the node, the address and the phase.
   The manifest was the desired state, and this is the actual state:

   <!-- verify: expect="Running" -->

   ```bash exec target=kube
   kubectl get pod web -o jsonpath='{.spec.nodeName}{"  "}{.status.podIP}{"  "}{.status.phase}{"\n"}'
   ```

## Logs and a shell

1. Ask the server from inside the Pod, then read what it logged:

   <!-- verify: timeout=60 expect="Welcome to nginx!" -->

   ```bash exec target=kube
   for i in $(seq 1 10); do kubectl exec web -- wget -qO- http://127.0.0.1 && break; sleep 1; done
   ```

   <!-- verify: expect="GET / HTTP/1.1" -->

   ```bash exec target=kube
   kubectl logs web | tail -n 3
   ```

## Applying twice

1. The same file, applied again, changes nothing: the actual state already matches the desired one.

   <!-- verify: expect="unchanged" -->

   ```bash exec target=kube
   cd ~/lab/pods && kubectl apply -f web.yaml
   ```

## A Pod that stays gone

1. Delete the Pod, and list the Pods:

   <!-- verify: expect="deleted" -->

   ```bash exec target=kube
   kubectl delete pod web
   ```

   <!-- verify: expect="No resources found" -->

   ```bash exec target=kube
   kubectl get pods
   ```

   Nothing brought it back: a Pod created alone has no one to keep it alive.
   A Deployment is that someone.
