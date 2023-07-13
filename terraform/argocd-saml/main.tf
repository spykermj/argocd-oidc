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

resource "random_uuid" "app_id" {}

data "azuread_client_config" "current" {}

locals {
  argo_hostname = "argocd.spykerman.co.uk"
  namespace     = "argocd"
}

module "argo_saml" {
  source         = "github.com/spykermj/tf-azure-auth/saml"
  redirect_paths = ["/api/dex/callback"]
  app_name       = "argocd-saml"
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
  hostname        = local.argo_hostname
  login_path      = "/auth/login"
  logo            = "../images/argo-stacked-color.png"
  verified_domain = false
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-kind"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
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

resource "kubernetes_manifest" "argo_cert" {
  manifest = yamldecode(
    templatefile("${path.module}/argocd-cert.yaml.tpl", {
      hostname  = local.argo_hostname
      namespace = local.namespace
    })
  )
}

resource "helm_release" "argocd" {
  depends_on = [kubernetes_manifest.argo_cert]
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.36.11"

  values = [
    templatefile("${path.module}/argocd-values.yaml.tpl", {
      issuer        = module.argo_saml.issuer
      azure_tenant  = data.azuread_client_config.current.tenant_id
      argo_hostname = local.argo_hostname
      cert          = base64encode(module.argo_saml.cert)
    })
  ]
}
