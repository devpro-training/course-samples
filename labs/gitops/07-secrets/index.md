# Secrets

Everything in the repository is readable by whoever can read the repository, and Git keeps every version of every file.
A password has no place in it.

## Encoded is not encrypted

1. A Secret manifest holds its values in base64, which is an encoding.
   The manifest is rendered by `kubectl` without touching the cluster:

   <!-- verify: expect="password: aHVudGVyMg==" -->

   ```bash exec target=docker
   kubectl create secret generic database --from-literal=password=hunter2 --dry-run=client --output yaml | grep -A1 '^data'
   ```

2. Anyone who reads the file reads the password:

   <!-- verify: expect="hunter2" -->

   ```bash exec target=docker
   echo "aHVudGVyMg==" | base64 -d; echo
   ```

## Git never forgets

1. Commit a secret by mistake in a scratch repository, then remove it in the next commit:

   <!-- verify: timeout=60 expect="commits: 2" -->

   ```bash exec target=docker
   rm -rf ~/lab/gitops/scratch && mkdir -p ~/lab/gitops/scratch && cd ~/lab/gitops/scratch && \
   git init -q . && \
   printf 'password: hunter2\n' > secret.yaml && git add . && git commit -q -m "Add the database" && \
   git rm -q secret.yaml && git commit -q -m "Remove the password" && \
   echo "commits: $(git log --format=%h | wc -l)"
   ```

2. The file is gone from the last commit, and it is in the history:

   <!-- verify: expect="Add the database" -->

   ```bash exec target=docker
   cd ~/lab/gitops/scratch && \
   ls | wc -l && \
   git log --oneline -S hunter2
   ```

   The only remedy is to consider the secret as published, and to change it.

## What stays outside Git

The reconciler only prunes the objects that carry its label, so an object created by hand is left alone.
This is how a secret can exist in the cluster without being in the repository, and it is also a gap: nothing says it exists.

1. Create a Secret without the label, and wait for two passes of the reconciler:

   <!-- verify: timeout=60 expect="secrets: 1" -->

   ```bash exec target=docker
   kubectl --namespace shop create secret generic database --from-literal=password=hunter2 && \
   sleep 12; \
   echo "secrets: $(kubectl --namespace shop get secrets --no-headers | wc -l)"
   ```

2. Stop the reconciler:

   <!-- verify: timeout=30 expect="reconcilers running: 0" -->

   ```bash exec target=docker
   pkill -f "^bash -c while true" ; sleep 1; \
   echo "reconcilers running: $(pgrep -fc '^bash -c while true')"
   ```
