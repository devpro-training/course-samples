# Flux and Terraform

A new cluster is two things: infrastructure, which Terraform makes, and what runs in it, which Flux fills from Git.
The provider of Flux makes the join one resource.

---

## Who does what

![Terraform makes the cluster, its credentials and the Git token, the provider commits the Flux manifests to a folder of the repository and installs the controllers, which then pull the folders of the layers and apply them, with the key of the secrets given by Terraform or by hand](../assets/flux-terraform-dark.svg#gh-dark-mode-only)
![Terraform makes the cluster, its credentials and the Git token, the provider commits the Flux manifests to a folder of the repository and installs the controllers, which then pull the folders of the layers and apply them, with the key of the secrets given by Terraform or by hand](../assets/flux-terraform.svg#gh-light-mode-only)

Terraform                                  | Flux
-------------------------------------------|-----------------------------------------------------------
The cluster, its nodes and its network     | The platform: ingress, certificates, policies, controllers
Flux itself, once, and its folder          | The applications, from the folder
The first credentials (a token, a key)     | Their sync, health, drift and prune

- **The folder is the contract**: Terraform names `clusters/<name>`, and Flux follows what is in it.
- **A change of an application is never a `terraform apply`**: it is a commit.
- **The upgrade of Flux is a change of the resource**, or a commit of the manifests if the folder owns them.

---

## The provider

- **`fluxcd/flux`** is the provider of the Flux project, listed as a community provider by the registry (version 1.9.6 on 1 October 2026).
- **`flux_bootstrap_git`** "commits Flux components to a Git repository and configures a Kubernetes cluster to sync from that same repository": the resource of `flux bootstrap git`.
- **Its arguments**: `path` (the folder, which cannot change), `namespace`, `components`, `interval`, `version`, and `embedded_manifests`, which takes the manifests from the provider binary instead of from GitHub.
- **The provider block** carries the credentials: a `kubernetes` block for the cluster, and a `git` block for the repository with `url`, `branch`, and `http` (username, password, `allow_insecure_http`) or `ssh`.

---

## The code

The same resource the lab ran by hand, written as the maintainer's repositories write it.
This file was checked with `terraform init`, `validate` and `plan` in the lab image, with no cluster:

```terraform
terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.9"
    }
  }
}

variable "git_url" {
  type = string
}

variable "git_token" {
  type      = string
  sensitive = true
}

variable "cluster_context" {
  type = string
}

provider "flux" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = var.cluster_context
  }
  git = {
    url    = var.git_url
    branch = "main"
    http = {
      username            = "git"
      password            = var.git_token
      allow_insecure_http = true
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path               = "clusters/${var.cluster_context}"
  embedded_manifests = true
}
```

- **`allow_insecure_http`** is for a lab server with no TLS, and a real repository uses HTTPS or SSH.
- **The `apply` was not run here**: it is what `flux bootstrap git` did in the lab, with the same arguments.

---

## With a cloud cluster

The module of a cluster and the module of Flux are separate, and the second only needs the endpoint and the credentials of the first:

```terraform
module "cluster" {
  source = "./modules/cluster"
  name   = var.cluster_name
}

provider "flux" {
  kubernetes = {
    host                   = "https://${module.cluster.endpoint}"
    cluster_ca_certificate = base64decode(module.cluster.ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
  git = {
    url  = var.git_repository_url
    http = { username = "git", password = var.git_token }
  }
}

module "flux" {
  source           = "./modules/flux"
  flux_target_path = "clusters/${var.cluster_name}"
  depends_on       = [module.cluster]
}
```

- **The pattern is the one of a GKE Autopilot example of the author**: a cluster module, a module with the one resource `flux_bootstrap_git`, an `exec` plugin for the token of the cloud, and a token for Git as a sensitive variable.
- **The same module serves an AKS cluster**: only the cluster module and its `exec` command change.
- **To rotate the token of Git**: change the `password` of the provider block, and `terraform apply`.

---

## The order, and the way back

Step                                  | Why it is in that order
--------------------------------------|----------------------------------------------------------------------------------------
The cluster                           | Nothing else exists without it
`flux_bootstrap_git`                  | It commits the folder and installs the controllers, which then pull the rest
The key of the secrets, by Terraform or by hand | A layer that holds secrets fails until the key exists, then retries, so the key comes first
Flux applies the platform, then the apps | By `dependsOn` and `wait`, with no Terraform
`terraform destroy`, in reverse        | `delete_git_manifests` defaults to `true`: the manifests leave the repository, then Flux is removed, then the cluster

- **State holds the credentials**: the token of Git and the identity of the cluster are in the state, which is encrypted and has access control.
- **A new environment is a variable file**: a name, a context, a branch.
- **The other way**: the Flux bootstrap by command in a pipeline, which is what the lab does, with no state to protect and a command to keep idempotent.
