terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.39.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }

  required_version = "1.5.1"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-kind"
  }
}

locals {
  argo_hostname = "argocd.spykerman.co.uk"
}

module "argocd_azure_application" {
  source   = "./oidc"
  hostname = local.argo_hostname
  app_name = "argocd"
  app_roles = [
    {
      description  = "ArgoCD Admin"
      display_name = "ArgoCD Admin"
      value        = "Admin"
    },
    {
      description  = "ArgoCD Read Only"
      display_name = "ArgoCD Viewer"
      value        = "Viewer"
    },
  ]
  redirect_paths = ["/auth/callback"]
  logout_path    = "/logout"
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "guestbook" {
  metadata {
    name = "guestbook"
  }
}

resource "kubernetes_secret" "argocd_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    "oidc.azure.clientId"     = module.argocd_azure_application.application_id
    "oidc.azure.clientSecret" = module.argocd_azure_application.client_secret
  }

  lifecycle {
    ignore_changes = [data]
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.36.11"

  values = [
    templatefile("${path.module}/argocd-values.yaml.tpl", {
      azure_tenant  = module.argocd_azure_application.tenant_id
      argo_hostname = local.argo_hostname
    })
  ]
}
