# A second cluster

Rancher manages clusters it did not create.
The machine `kube` gets a k3s cluster of its own, then registers it in Rancher, as any existing cluster would be: one manifest applied by its administrator.
The terminal of `docker` is the platform team, the terminal of `kube` the administrator of that cluster.

<!-- include: ../../shared/setup-k3s.md -->

## The name of Rancher, for the Pods

The agent that Rancher installs runs as a Pod, which resolves names through the DNS of its cluster, and that DNS does not know the machines of the lab.
A real installation has a DNS record for the hostname of Rancher, and the lab adds one to CoreDNS, which k3s reads from the ConfigMap `coredns-custom`.

1. Look up the address of `docker` from this machine, and write it for CoreDNS:

   <!-- verify: expect="configmap/coredns-custom created" -->

   ```bash exec target=kube
   UI_ADDRESS=$(getent hosts "${UI_HOST}" | cut -d ' ' -f 1) && echo "${UI_HOST} is ${UI_ADDRESS}" && \
   kubectl apply -f - <<EOT
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: coredns-custom
     namespace: kube-system
   data:
     rancher.server: |
       ${UI_HOST}:53 {
         hosts {
           ${UI_ADDRESS} ${UI_HOST}
         }
       }
   EOT
   ```

2. CoreDNS mounts that ConfigMap as an optional volume, which is empty in a Pod started before it existed, so CoreDNS is restarted:

   <!-- verify: timeout=120 expect="successfully rolled out" -->

   ```bash exec target=kube
   kubectl --namespace kube-system rollout restart deployment coredns > /dev/null && \
   kubectl --namespace kube-system rollout status deployment coredns --timeout=90s
   ```

3. A Pod now resolves the name.
   The final dot makes busybox skip the search domains of the Pod:

   <!-- verify: requires=network timeout=120 expect="answers: 1" -->

   ```bash exec target=kube
   echo "answers: $(kubectl run dns --rm -i --restart=Never --image "${BUSYBOX_IMAGE}" -- nslookup "${UI_HOST}." 2> /dev/null | grep -c '^Name:')"
   ```

## The cluster in Rancher

1. In the terminal of `docker`, declare the cluster.
   A provisioning `Cluster` with no specification is a cluster to import:

   <!-- verify: expect="cluster.provisioning.cattle.io/kube created" -->

   ```bash exec target=docker
   kubectl apply -f - <<EOT
   apiVersion: provisioning.cattle.io/v1
   kind: Cluster
   metadata:
     name: kube
     namespace: fleet-default
   spec: {}
   EOT
   ```

2. Rancher gives it an identifier and a registration token, kept in a Secret, which expires and is rotated:

   <!-- verify: timeout=90 expect="expiresAt:" -->

   ```bash exec target=docker
   for i in $(seq 1 40); do \
     CLUSTER_ID=$(kubectl --namespace fleet-default get clusters.provisioning.cattle.io kube -o jsonpath='{.status.clusterName}'); \
     [ -n "${CLUSTER_ID}" ] && kubectl --namespace "${CLUSTER_ID}" get secret crt-token-default-token > /dev/null 2>&1 && break; sleep 2; \
   done; \
   echo "identifier: ${CLUSTER_ID}" && \
   kubectl --namespace "${CLUSTER_ID}" get clusterregistrationtokens.management.cattle.io default-token -o yaml | grep -E "^  (command|expiresAt|tokenSecretName):"
   ```

## The registration

The administrator of `kube` has an account in Rancher, here `admin`, and reads the registration command with the API.

1. In the terminal of `kube`, trust the authority of Rancher.
   The first download cannot be checked, so its fingerprint is compared with the one `docker` printed in the install step, by a person, once:

   <!-- verify: requires=network -->

   ```bash exec target=kube
   cd ~/lab && wget -qO ca.pem --no-check-certificate "https://${UI_HOST}/cacerts" && sha256sum ca.pem
   ```

   ```bash exec target=docker
   sha256sum ~/lab/ca.pem
   ```

2. Log in to the API.
   The answer holds a token, which every later call presents:

   <!-- verify: requires=network expect="token-" -->

   ```bash exec target=kube
   cd ~/lab && \
   wget -qO- --ca-certificate ca.pem --header "Content-Type: application/json" \
     --post-data "{\"username\":\"admin\",\"password\":\"${UI_ADMIN_PASSWORD}\",\"responseType\":\"token\",\"ttl\":7200000}" \
     "https://${UI_HOST}/v3-public/localProviders/local?action=login" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' > token && \
   cut -d ':' -f 1 token
   ```

3. Find the cluster by its name, and read its registration command:

   <!-- verify: requires=network expect="v3/import/" -->

   ```bash exec target=kube
   cd ~/lab && \
   CLUSTER_ID=$(wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer $(cat token)" "https://${UI_HOST}/v3/clusters?name=kube" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"][0]["id"])') && echo "${CLUSTER_ID}" > cluster-id && \
   wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer $(cat token)" "https://${UI_HOST}/v3/clusterregistrationtokens?clusterId=${CLUSTER_ID}" \
     | python3 -c 'import json,sys; print([t["manifestUrl"] for t in json.load(sys.stdin)["data"] if t["name"] == "default-token"][0])' > manifest-url && \
   sed 's#/import/[a-z0-9]*_#/import/<token>_#' manifest-url
   ```

4. Download the manifest, and read it before applying it.
   It names the address of Rancher and the checksum of its authority, which is the `sha256sum` of the first step:

   <!-- verify: requires=network expect="CATTLE_CA_CHECKSUM" -->

   ```bash exec target=kube
   cd ~/lab && wget -qO import.yaml --ca-certificate ca.pem "$(cat manifest-url)" && \
   grep "^kind:" import.yaml | sort | uniq -c && \
   grep -A 1 -E "name: CATTLE_(SERVER|CA_CHECKSUM)$" import.yaml
   ```

5. Apply it.
   The administrator of the cluster does it, with `cluster-admin`, and nothing is opened towards the cluster: the agent calls Rancher:

   <!-- verify: expect="deployment.apps/cattle-cluster-agent created" -->

   ```bash exec target=kube
   kubectl apply -f ~/lab/import.yaml
   ```

6. In the terminal of `docker`, wait until Rancher sees the cluster ready:

   <!-- verify: timeout=360 expect="kube-kubeconfig" -->

   ```bash exec target=docker
   for i in $(seq 1 100); do [ "$(kubectl --namespace fleet-default get clusters.provisioning.cattle.io kube -o jsonpath='{.status.ready}')" = true ] && break; sleep 3; done; \
   kubectl --namespace fleet-default get clusters.provisioning.cattle.io
   ```

7. In the terminal of `kube`, Rancher redeployed its agent with the settings of the cluster, and installed the agent of Fleet:

   <!-- verify: timeout=180 expect="cattle-fleet-system" -->

   ```bash exec target=kube
   for i in $(seq 1 60); do kubectl get deployments --all-namespaces --no-headers 2> /dev/null | grep -q "fleet-agent .*1/1" && break; sleep 3; done; \
   kubectl get deployments --all-namespaces | grep -E "^(NAMESPACE|cattle)"
   ```

## The interface

1. [**Cluster Management**](:action:ui.clusters) lists both clusters, `kube` as **Imported** with the distribution **K3s** and its version.
   **Import Existing** is the same import from the interface: **Generic** for any cluster, or **Amazon EKS**, **Azure AKS** and **Google GKE**, read with a cloud credential.

2. [Explore `kube`](:action:ui.kube): the same explorer as for `local`, for a cluster of another machine, through the tunnel of its agent.
