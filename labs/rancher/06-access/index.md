# Access, users and projects

Rancher is the one door to every cluster: a person signs in once, with a local account or a company directory, and reaches each cluster through the authentication proxy of Rancher, with the roles given to them there.
The cluster sees the person, not a shared account, by Kubernetes impersonation.

## Through the proxy

1. In the terminal of `kube`, ask Rancher for a kubeconfig, as the button **Download KubeConfig** does.
   Its server is Rancher, under `/k8s/clusters/<identifier>`, not the API of k3s:

   <!-- verify: requires=network expect="/k8s/clusters/c-" -->

   ```bash exec target=kube
   cd ~/lab && \
   wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer $(cat token)" --post-data "" \
     "https://${UI_HOST}/v3/clusters/$(cat cluster-id)?action=generateKubeconfig" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["config"])' > rancher-admin.yaml && \
   grep "server:" rancher-admin.yaml
   ```

2. Ask the cluster who is calling, through Rancher.
   The user is the one of Rancher, with the groups and the extra fields the proxy adds:

   <!-- verify: requires=network expect="requesthost" -->

   ```bash exec target=kube
   kubectl --kubeconfig ~/lab/rancher-admin.yaml get nodes && \
   kubectl --kubeconfig ~/lab/rancher-admin.yaml auth whoami
   ```

3. With the kubeconfig of k3s itself, the cluster shows how: one service account per Rancher user, allowed to impersonate that user and nothing else:

   <!-- verify: expect="cattle-impersonation-user-" -->

   ```bash exec target=kube
   kubectl --namespace cattle-impersonation-system get serviceaccounts && \
   kubectl get clusterroles | grep "^cattle-impersonation"
   ```

## A user and a project

The platform team gives a team a project, a group of namespaces of one cluster, and the role `project-member` in it.

1. In the terminal of `docker`, log in to the API, and create the user.
   The global role `user` lets the account sign in and see only what it is given:

   <!-- verify: requires=network expect="user id: u-" -->

   ```bash exec target=docker
   cd ~/lab && \
   wget -qO- --ca-certificate ca.pem --header "Content-Type: application/json" \
     --post-data "{\"username\":\"admin\",\"password\":\"${UI_ADMIN_PASSWORD}\",\"responseType\":\"token\",\"ttl\":7200000}" \
     "https://${UI_HOST}/v3-public/localProviders/local?action=login" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' > token && \
   wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer $(cat token)" --header "Content-Type: application/json" \
     --post-data "{\"username\":\"${DEV_USER}\",\"password\":\"${DEV_PASSWORD}\",\"mustChangePassword\":false,\"enabled\":true}" "https://${UI_HOST}/v3/users" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' > dev-id && \
   wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer $(cat token)" --header "Content-Type: application/json" \
     --post-data "{\"globalRoleId\":\"user\",\"userId\":\"$(cat dev-id)\"}" "https://${UI_HOST}/v3/globalrolebindings" > /dev/null && \
   echo "user id: $(cat dev-id)"
   ```

2. The API wrote Kubernetes resources: the user, its global role binding, and its password, hashed in a Secret of `cattle-local-user-passwords`:

   <!-- verify: expect="Default Admin" -->

   ```bash exec target=docker
   kubectl get users.management.cattle.io -o custom-columns=ID:.metadata.name,NAME:.displayName,USERNAME:.username | grep -v "<none>" && \
   kubectl --namespace cattle-local-user-passwords get secrets
   ```

3. Create the project in the cluster `kube`, and make the user a member of it:

   <!-- verify: expect="projectroletemplatebinding.management.cattle.io/dev-shop created" -->

   ```bash exec target=docker
   CLUSTER_ID=$(kubectl --namespace fleet-default get clusters.provisioning.cattle.io kube -o jsonpath='{.status.clusterName}') && \
   kubectl apply -f - <<EOT
   apiVersion: management.cattle.io/v3
   kind: Project
   metadata:
     name: shop
     namespace: ${CLUSTER_ID}
   spec:
     clusterName: ${CLUSTER_ID}
     displayName: shop
   EOT
   for i in $(seq 1 20); do kubectl get namespace "${CLUSTER_ID}-shop" > /dev/null 2>&1 && break; sleep 1; done; \
   kubectl apply -f - <<EOT
   apiVersion: management.cattle.io/v3
   kind: ProjectRoleTemplateBinding
   metadata:
     name: dev-shop
     namespace: ${CLUSTER_ID}-shop
   projectName: ${CLUSTER_ID}:shop
   roleTemplateName: project-member
   userName: $(cat ~/lab/dev-id)
   EOT
   ```

4. In the terminal of `kube`, the administrator of the cluster creates the namespace of the team in that project, with one annotation:

   <!-- verify: expect="namespace/shop created" -->

   ```bash exec target=kube
   kubectl apply -f - <<EOT
   apiVersion: v1
   kind: Namespace
   metadata:
     name: shop
     annotations:
       field.cattle.io/projectId: $(cat ~/lab/cluster-id):shop
   EOT
   ```

## As the team

1. Log in as the user, and ask for a kubeconfig of the cluster:

   <!-- verify: requires=network expect="/k8s/clusters/c-" -->

   ```bash exec target=kube
   cd ~/lab && \
   DEV_TOKEN=$(wget -qO- --ca-certificate ca.pem --header "Content-Type: application/json" \
     --post-data "{\"username\":\"${DEV_USER}\",\"password\":\"${DEV_PASSWORD}\",\"responseType\":\"token\",\"ttl\":7200000}" \
     "https://${UI_HOST}/v3-public/localProviders/local?action=login" | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])') && \
   wget -qO- --ca-certificate ca.pem --header "Authorization: Bearer ${DEV_TOKEN}" --post-data "" \
     "https://${UI_HOST}/v3/clusters/$(cat cluster-id)?action=generateKubeconfig" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["config"])' > rancher-dev.yaml && \
   grep "server:" rancher-dev.yaml
   ```

2. The user can deploy in the namespace of its project, and nowhere else.
   The role is checked by the cluster itself, since Rancher wrote it as RBAC there:

   <!-- verify: timeout=90 expect="deployment.apps/web created" -->

   ```bash exec target=kube
   for i in $(seq 1 30); do [ "$(kubectl --kubeconfig ~/lab/rancher-dev.yaml --namespace shop auth can-i create deployments)" = yes ] && break; sleep 2; done; \
   echo "in shop: $(kubectl --kubeconfig ~/lab/rancher-dev.yaml --namespace shop auth can-i create deployments)"; \
   echo "in default: $(kubectl --kubeconfig ~/lab/rancher-dev.yaml --namespace default auth can-i create deployments)"; \
   echo "nodes: $(kubectl --kubeconfig ~/lab/rancher-dev.yaml auth can-i list nodes 2> /dev/null)"; \
   kubectl --kubeconfig ~/lab/rancher-dev.yaml --namespace shop create deployment web --image "${WHOAMI_IMAGE}"
   ```

## The interface

1. [**Users & Authentication**](:action:ui.users) lists `admin` and `dev`, both of the provider **Local**.
   [**Auth Provider**](:action:ui.auth) lists what Rancher can delegate the sign-in to: Active Directory, FreeIPA and OpenLDAP, GitHub and Google, Microsoft Entra ID, Amazon Cognito, Keycloak and any OIDC or SAML provider.
   Groups of the directory then get roles, so a person who leaves the company loses every cluster at once.

2. [**Projects/Namespaces** of `kube`](:action:ui.projects) shows the project `shop` with its namespace, beside **Default** and **System**.
