locals {
  ad_app_display_name = "grafana"
  hostname            = "grafana.spykerman.co.uk"
}

data "azuread_client_config" "current" {}

module "grafana_azure_application" {
  source = "./oidc"
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
  app_name       = local.ad_app_display_name
  redirect_paths = ["/login/azuread", "/"]
  logout_path    = "/logout"
}

output "grafana_app_ids" {
 value = module.grafana_azure_application.app_role_ids
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana-azure-oauth2"
    namespace = kubernetes_namespace.grafana.id
  }

  data = {
    "GF_AUTH_AZUREAD_CLIENT_ID"     = module.grafana_azure_application.application_id
    "GF_AUTH_AZUREAD_CLIENT_SECRET" = module.grafana_azure_application.client_secret
  }
}
