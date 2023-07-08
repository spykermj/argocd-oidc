locals {
  ad_app_display_name = "grafana"
  hostname            = "grafana.spykerman.co.uk"
  namespace           = "monitoring"
}

data "azuread_client_config" "current" {}

module "grafana_azure_application" {
  app_name = local.ad_app_display_name
  app_roles = [
    {
      description  = "Grafana server admin users"
      display_name = "Grafana Server Admin"
      value        = "GrafanaAdmin"
    },
    {
      description  = "Grafana org admin users"
      display_name = "Grafana Org Admin"
      value        = "Admin"
    },
    {
      description  = "Grafana read only users"
      display_name = "Grafana Viewer"
      value        = "Viewer"
    },
    {
      description  = "Grafana Editor Users"
      display_name = "Grafana Editor"
      value        = "Editor"
    },
  ]
  hostname       = local.hostname
  logo           = "${path.module}/images/Grafana_logo.svg.png"
  logout_path    = "/logout"
  redirect_paths = ["/login/azuread", "/"]
  source         = "github.com/spykermj/tf-azure-auth/oidc"
}

output "grafana_app_ids" {
  value = module.grafana_azure_application.app_role_ids
}

resource "kubernetes_namespace" "kps" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana-azure-oauth2"
    namespace = kubernetes_namespace.kps.id
  }

  data = {
    "GF_AUTH_AZUREAD_CLIENT_ID"     = module.grafana_azure_application.application_id
    "GF_AUTH_AZUREAD_CLIENT_SECRET" = module.grafana_azure_application.client_secret
  }
}

resource "kubernetes_manifest" "grafana_cert" {
  manifest = yamldecode(
    templatefile("${path.module}/grafana-cert.yaml.tpl", {
      hostname  = local.hostname
      namespace = local.namespace
    })
  )
}

resource "helm_release" "kps" {
  name       = "kps"
  namespace  = kubernetes_namespace.kps.id
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "47.1.0"

  values = [
    templatefile("${path.module}/kps-values.yaml.tpl", {
      azure_tenant     = module.grafana_azure_application.tenant_id
      grafana_hostname = local.hostname
    })
  ]
}
