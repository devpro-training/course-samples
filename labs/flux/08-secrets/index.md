# Secrets

A repository that holds everything cannot hold a password in clear.
SOPS encrypts the values of a file and leaves its keys readable, and Flux decrypts it when it applies it, with a key that only the cluster has.

## Why base64 is not enough

1. A Kubernetes Secret, written the way a manifest holds it.
   The value is encoded, not encrypted: anyone who reads the file reads the password.
   The file is only printed, and never committed:

   <!-- verify: expect="decoded: s3cr3t-lab-value" -->

   ```bash exec target=docker
   kubectl create secret generic shop-db --namespace shop --from-literal password="${SHOP_DB_PASSWORD}" --dry-run=client --output yaml | tee ~/lab/secret-in-clear.yaml
   echo "decoded: $(grep ' password:' ~/lab/secret-in-clear.yaml | cut -d ' ' -f 4 | base64 -d)"
   ```

## The key

1. Make a key pair for the cluster.
   The file holds the private key, and the line `Public key:` is what encrypts.
   Both are made here, on the machine of the lab:

   <!-- verify: expect="recipient: age1" -->

   ```bash exec target=docker
   cd ~/lab && age-keygen -o age.agekey 2> /dev/null ; chmod 600 age.agekey && \
   echo "recipient: $(age-keygen -y age.agekey)"
   ```

2. Give the private key to the cluster, as a Secret of the namespace of Flux.
   The name of the key in the Secret must end with `.agekey`, so that Flux knows it is an age key.
   It is the only secret the cluster is given by hand, once:

   <!-- verify: expect="secret/sops-age created" -->

   ```bash exec target=docker
   kubectl --namespace flux-system create secret generic sops-age --from-file=age.agekey=$HOME/lab/age.agekey
   ```

3. Tell SOPS, with a file at the root of the repository, what to encrypt and for whom: the values of `data` and `stringData` of the files named `secret.yaml`, for the public key:

   <!-- verify: expect="age1" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   cat > .sops.yaml <<EOT
   creation_rules:
     - path_regex: .*/secret\.yaml$
       encrypted_regex: ^(data|stringData)$
       age: $(age-keygen -y ~/lab/age.agekey)
   EOT
   cat .sops.yaml
   ```

## An encrypted Secret

1. Write the Secret into the folder of the shop, encrypt it in place, and add it to the list:

   <!-- verify: expect="ENC[AES256_GCM" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   kubectl create secret generic shop-db --namespace shop --from-literal password="${SHOP_DB_PASSWORD}" --dry-run=client --output yaml > apps/shop/secret.yaml && \
   sops --encrypt --in-place apps/shop/secret.yaml && \
   echo "  - secret.yaml" >> apps/shop/kustomization.yaml && \
   grep -E "^(kind| +password| +name)" apps/shop/secret.yaml | cut -c 1-60
   ```

   Only the value is encrypted: the kind, the name and the key `password` are readable, so a review and a `git diff` still say what changed.
   `sops` also wrote its own block, `sops:`, with the encrypted copy of the data key for each recipient, and a MAC that detects a modified file.

2. Commit it.
   The Kustomization `shop` was not told about SOPS yet, which is the mistake to make once:

   <!-- verify: timeout=120 expect="ready: False" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git add -A && git commit -q -m "Add the database password of the shop, encrypted" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   flux reconcile kustomization shop --timeout 30s > /dev/null 2>&1 ; \
   echo "ready: $(flux get kustomization shop | tail -1 | cut -f 4)"
   ```

3. Flux read the file, saw the block `sops:`, and refused to apply a Secret it cannot read.
   The message says what to configure:

   <!-- verify: expect="configuring decryption is required" -->

   ```bash exec target=docker
   flux get kustomization shop | tail -1 | cut -f 5 | cut -c 1-240
   ```

## Decrypt in the cluster

1. Add the decryption to the Kustomization, with the same command that wrote it, and the Secret of the key:

   <!-- verify: expect="provider: sops" -->

   ```bash exec target=docker
   cd ~/lab/fleet && \
   flux create kustomization shop --source GitRepository/flux-system --path ./apps/shop --prune true --interval 1m --wait true --depends-on infra \
     --decryption-provider sops --decryption-secret sops-age --export > clusters/hub/shop.yaml && \
   grep -A3 decryption clusters/hub/shop.yaml
   ```

2. Commit, and the Secret is applied:

   <!-- verify: timeout=180 expect="password in the cluster: s3cr3t-lab-value" -->

   ```bash exec target=docker
   cd ~/lab/fleet && git commit -q -am "Decrypt the secrets of the shop" && git push -q && \
   flux reconcile kustomization flux-system --with-source > /dev/null 2>&1 ; \
   for i in $(seq 1 30); do flux reconcile kustomization shop --timeout 30s > /dev/null 2>&1 ; kubectl --namespace shop get secret shop-db > /dev/null 2>&1 && break; sleep 3; done; \
   echo "password in the cluster: $(kubectl --namespace shop get secret shop-db --output jsonpath='{.data.password}' | base64 -d)"
   ```

3. And the repository never saw it:

   <!-- verify: expect="clear text in the history: 0" -->

   ```bash exec target=docker
   cd ~/lab/fleet && echo "clear text in the history: $(git log -p --all | grep -c "${SHOP_DB_PASSWORD}")"
   ```

## Who can read what

Place                      | Holds                    | Who reads it
---------------------------|--------------------------|--------------------------------------------------
The repository             | The encrypted values     | Anyone with access, who learns names and structure
The Secret `sops-age`      | The private key          | Whoever reads the namespace `flux-system`
The Secret `shop-db`       | The value                | Whoever reads the namespace `shop`
`~/lab/age.agekey`         | The private key          | The user of the machine

- **The private key is the secret of secrets**: losing it loses every value, leaking it opens the whole history of the repository, so it is kept outside the cluster too, in a password manager or a vault.
- **A value is rotated by encrypting a new file**, and the key is rotated by `sops updatekeys` and a new Secret: the old history stays readable with the old key.
