locals {
  argo_hostname = "argocd.spykerman.co.uk"
}

module "argocd_azure_application" {
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
  hostname       = local.argo_hostname
  logo           = "../images/argo-stacked-color.png"
  logout_path    = "/logout"
  redirect_paths = ["/auth/callback"]
  source         = "github.com/spykermj/tf-azure-auth/oidc"
}

output "argocd_app_roles" {
  value = module.argocd_azure_application.app_role_ids
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
