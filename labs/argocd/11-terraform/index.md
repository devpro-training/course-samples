# Argo CD and Terraform

A new environment is a cluster, and a cluster is two things: infrastructure, which Terraform makes, and what runs in it, which Argo CD fills from Git.

---

## Who does what

![Terraform creates the cluster and the identity Argo CD uses on it, installs Argo CD and the root Application in the hub, and writes the Secret that registers the cluster, then Argo CD pulls the repository and syncs the platform and the applications to the new cluster](../assets/argocd-terraform-dark.svg#gh-dark-mode-only)
![Terraform creates the cluster and the identity Argo CD uses on it, installs Argo CD and the root Application in the hub, and writes the Secret that registers the cluster, then Argo CD pulls the repository and syncs the platform and the applications to the new cluster](../assets/argocd-terraform.svg#gh-light-mode-only)

---

## The line between them

Terraform                                     | Argo CD
----------------------------------------------|----------------------------------------------------------
The cluster and its nodes, the network        | The platform: ingress, certificates, policies, controllers
The identity Argo CD uses on the cluster      | The applications, from folders and from clusters
The Secret that registers the cluster         | Their sync, health, history and rollback
Argo CD itself and the root, once             | Argo CD afterwards, if the root points to it

- **The Secret and its labels are the contract**: Terraform writes it, the ApplicationSets read it, and nothing else passes between them.
- **A change of an application is never a `terraform apply`**: it is a commit, and Terraform stays out of what changes every day.

---

## What it needs

1. **A repository with the layers**, which exists before the first environment: a folder of Applications and ApplicationSets (`bootstrap/`), a `platform/` for what every cluster needs, and the applications.
   It is the app of apps of the bootstrap step, and a new cluster brings nothing to it.

2. **A hub with Argo CD**, installed once, with a root Application that points to `bootstrap/`.

3. **A path from the hub to the new API server**: the address, the certificate authority and a token, or an agent on the cluster that connects out.

4. **A label contract**: the labels a cluster Secret carries (`env`, `region`) are what the generators select on.

5. **A place for the state**, encrypted and with access control, since it holds the token of the identity Terraform made.

---

## The providers

Provider                 | Role in this chain
-------------------------|------------------------------------------------------------------------------------------------
Cloud provider           | The cluster itself: `azurerm`, `aws`, `google`, as in the Azure course
`hashicorp/helm`         | Installs the chart `argo-cd`, then the chart `argocd-apps` that makes the root Application
`hashicorp/kubernetes`   | The identity in the new cluster (ServiceAccount, binding, token), and the cluster Secret in the hub
`argoproj-labs/argocd`   | Manages the resources of Argo CD through its API: `argocd_cluster`, `argocd_application`, `argocd_application_set`, `argocd_project`, `argocd_repository`

- The provider `argoproj-labs/argocd` is a community one in the registry (version 7.17.1 on 5 October 2026).
  Its documentation says it "is not concerned with the installation/configuration of ArgoCD itself": it needs an Argo CD that exists, with an API server reachable from where Terraform runs, with `server_addr` and a token, a port-forward or the core mode.

- The `kubernetes` provider writes the cluster Secret without the API of Argo CD: it only needs access to the namespace `argocd` of the hub, and the Secret is the resource that Argo CD reads.
  This course uses it, which keeps Terraform out of the API server of Argo CD.

---

## Step 1: Argo CD and the root

The Helm provider installs the chart of Argo CD, pinned, then the chart `argocd-apps`, which makes the root Application: the only Application made by hand.
This file was checked with `terraform validate` in the lab image:

```terraform
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.3"
  namespace        = "argocd"
  create_namespace = true
}

resource "helm_release" "root" {
  name       = "root"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.6"
  namespace  = "argocd"
  values = [yamlencode({
    applications = { root = {
      namespace   = "argocd"
      project     = "default"
      source      = { repoURL = "http://git.example/deploy.git", targetRevision = "main", path = "bootstrap" }
      destination = { server = "https://kubernetes.default.svc", namespace = "argocd" }
      syncPolicy  = { automated = { prune = true, selfHeal = true } }
    } }
  })]
  depends_on = [helm_release.argocd]
}
```

- **`kubernetes_manifest` does not work for the root**: it reads the definition of `Application` at the plan, which does not exist before Argo CD is installed.
  The chart `argocd-apps` installs the resource after the chart `argo-cd`, in the order `depends_on` gives.

---

## Step 2: the cluster, registered

Terraform makes the identity in the new cluster, and the Secret in the hub, with two `kubernetes` providers that name two contexts.
This was applied to a real cluster in the lab image: four resources, and the application of the ApplicationSet appeared with no command:

```terraform
provider "kubernetes" {
  alias          = "hub"
  config_path    = "~/.kube/config"
  config_context = var.hub_context
}

provider "kubernetes" {
  alias          = "new"
  config_path    = "~/.kube/config"
  config_context = var.new_context
}

resource "kubernetes_secret_v1" "manager_token" {
  provider = kubernetes.new
  metadata {
    name        = "argocd-manager-token"
    namespace   = "kube-system"
    annotations = { "kubernetes.io/service-account.name" = "argocd-manager" }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_secret_v1" "cluster" {
  provider = kubernetes.hub
  metadata {
    name      = format("cluster-%s", var.new_name)
    namespace = "argocd"
    labels    = { "argocd.argoproj.io/secret-type" = "cluster", env = var.new_name }
  }
  data = {
    name   = var.new_name
    server = var.new_server
    config = jsonencode({
      bearerToken     = kubernetes_secret_v1.manager_token.data["token"]
      tlsClientConfig = { insecure = false, caData = base64encode(kubernetes_secret_v1.manager_token.data["ca.crt"]) }
    })
  }
}
```

- The ServiceAccount and its binding to `cluster-admin` are two more resources of the same provider, and the token goes from one provider to the other without anyone reading it.
- **The identity can be narrower than `cluster-admin`**: the documentation of Argo CD says the default role can be narrowed to the namespaces and resources it should write.

---

## The argocd provider, instead

The same registration can go through the API of Argo CD, as the documentation of the provider shows for a cluster, with the same identity resources:

```terraform
resource "argocd_cluster" "new" {
  server = var.new_server
  name   = var.new_name

  config {
    bearer_token = kubernetes_secret_v1.manager_token.data["token"]
    tls_client_config {
      ca_data = kubernetes_secret_v1.manager_token.data["ca.crt"]
    }
  }
}
```

- **What changes**: Terraform needs the API of Argo CD, a login or a token of it, and a network path to it, where the Secret only needs the Kubernetes API of the hub.
- **What it adds**: Argo CD validates the cluster at once, and the resources `argocd_project`, `argocd_repository` and `argocd_application` are managed the same way.
- This snippet was written from the documentation of the provider and not run in the lab.

---

## The order, and the way back

Step                                        | Why it is in that order
--------------------------------------------|------------------------------------------------------------------------------------
1. The cluster                              | Nothing else exists without it
2. The identity and the Secret              | The Secret is the first thing Argo CD reads about it
3. The generators make the Applications     | By labels: the platform wave first, then the applications, with a health check on Applications
4. `terraform destroy`, in reverse          | The Secret goes first: Argo CD stops deploying, and the Applications of the cluster go with their generator, then the cluster is deleted

- **Delete the Secret before the cluster**: Argo CD stops deploying to a cluster that is going away, and its Application goes with its generator.
- **A new environment is a variable file**: a name, a server, a label.

---

## The other way: one Argo CD per cluster

Terraform can also install Argo CD in each new cluster, with its own root Application that points to `clusters/<name>` of the same repository, which is step 1 once per cluster.

Hub                                           | One Argo CD per cluster
----------------------------------------------|-------------------------------------------------------
One place to see everything                   | A view per cluster, or an aggregation on top
The hub holds a credential for each cluster   | No credential leaves a cluster: each pulls, and only reads Git
One failure domain                            | One per cluster
ApplicationSets over clusters                 | The same files, once per cluster, in a folder per cluster
A path from the hub to every API server       | Only a path from every cluster to Git

- **The agent is a third way**: the project `argocd-agent` of `argoproj-labs` keeps the central view and moves the connection the other way, with agents on the clusters that connect out to the hub.

- References: [Terraform provider for Argo CD](https://github.com/argoproj-labs/terraform-provider-argocd), [cluster bootstrapping](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/), [declarative setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/), [argocd-agent](https://argocd-agent.readthedocs.io/latest/).
