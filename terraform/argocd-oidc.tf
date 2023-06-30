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
      source = "hashicorp/helm"
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
    config_path = "~/.kube/config"
    config_context = "kind-kind"
  }
}

# https://learn.microsoft.com/en-us/graph/permissions-reference
locals {
  ad_app_display_name = "argocd"
  microsoft_graph = {
    app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    scopes = [
      "37f7f235-527c-4136-accd-4a02d197296e", # openid
      "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0", # email
      "14dad69e-099b-42c9-810b-d002981feec1", # profile
    ]
  }
  hostname = "argocd.spykerman.co.uk"
}


data "azuread_client_config" "current" {}

resource "random_uuid" "app_id" {}

resource "random_uuid" "admin" {}
resource "random_uuid" "viewer" {}

resource "azuread_application" "this" {
  display_name            = local.ad_app_display_name
  owners                  = [data.azuread_client_config.current.object_id]
  sign_in_audience        = "AzureADMyOrg"
  prevent_duplicate_names = true

  required_resource_access {
    resource_app_id = local.microsoft_graph.app_id
    dynamic "resource_access" {
      for_each = local.microsoft_graph.scopes
      content {
        id   = resource_access.value
        type = "Scope"
      }
    }
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "ArgoCD Admin"
    display_name         = "ArgoCD Admin"
    value                = "Admin"
    id                   = random_uuid.admin.id
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "ArgoCD Read Only"
    display_name         = "ArgoCD Viewer"
    value                = "Viewer"
    id                   = random_uuid.viewer.id
  }

  web {
    redirect_uris = ["https://${local.hostname}/auth/callback"]
    logout_url    = "https://${local.hostname}/logout"

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  feature_tags {
    gallery    = true
    enterprise = true
  }
}

resource "azuread_service_principal" "this" {
  application_id               = azuread_application.this.application_id
  owners                       = [data.azuread_client_config.current.object_id]
  app_role_assignment_required = true
}

resource "azuread_application_password" "this" {
  display_name          = "grafana secret"
  application_object_id = azuread_application.this.id
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

resource "kubernetes_secret" "example" {
  metadata {
    name = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    "oidc.azure.clientId" = azuread_application.this.application_id
    "oidc.azure.clientSecret" = azuread_application_password.this.value
  }
}

resource "helm_release" "argocd" {
  name = "argocd"
  namespace = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "5.36.11"

  values = [
    templatefile("${path.module}/argocd-values.yaml.tpl",{
      azure_tenant = data.azuread_client_config.current.tenant_id
      argo_hostname = local.hostname
    })
  ]
}
