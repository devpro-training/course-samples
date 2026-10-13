# Push to the cluster

The usual way to deliver is to push: a pipeline, or a person, runs `kubectl apply` against the cluster.
It works, and it shows the limits that GitOps removes.

## A push

1. Apply the environment from the clone, as a pipeline would:

   <!-- verify: expect="deployment.apps/shop created" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   kubectl apply -k envs/dev
   ```

2. Wait for the application:

   <!-- verify: timeout=240 requires=network expect="successfully rolled out" -->

   ```bash exec target=docker
   for i in $(seq 1 60); do kubectl --namespace shop get deployment shop > /dev/null 2>&1 && break; sleep 2; done; \
   kubectl --namespace shop rollout status deployment/shop --timeout=200s
   ```

The cluster now matches the repository, and nothing keeps it that way.

## Credentials

- The pipeline that pushes holds a credential of the cluster, with the right to change it, and the cluster must accept connections from wherever the pipeline runs.
- Here the credential is the kubeconfig of this machine:

<!-- verify: expect="yes" -->

```bash exec target=docker
kubectl auth can-i '*' '*'
```

## Drift

Someone fixes an incident by hand, with the best intentions:

1. Scale the application:

   <!-- verify: expect="scaled" -->

   ```bash exec target=docker
   kubectl --namespace shop scale deployment shop --replicas 3
   ```

2. Nothing notices.
   The repository says 1 replica, the cluster runs 3, and a push only happens when someone pushes:

   <!-- verify: timeout=60 expect="replicas in the cluster: 3" -->

   ```bash exec target=docker
   sleep 5; \
   echo "replicas in the cluster: $(kubectl --namespace shop get deployment shop --output jsonpath='{.spec.replicas}')"
   ```

3. The difference is in the output of `kubectl diff`, which compares the files with the cluster.
   It exits with 1 when they differ:

   <!-- verify: expect="replicas: 3" -->

   ```bash exec target=docker
   cd ~/lab/gitops/platform && \
   { kubectl diff -k envs/dev | grep -E '^[-+] +replicas' || true; }
   ```

   The line with `-` is the cluster, the line with `+` is the repository.

4. Nobody ran that command.
   The repository and the cluster have been different for a while, and the only way to find out is to look.
   Reconciling is the same command, run over and over by a program instead of a person: the next step.
