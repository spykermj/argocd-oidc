output "application_id" {
  description = "The ID for this application. Will be used as client id."
  value = azuread_application.this.application_id
}

output "client_secret" {
  description = "A secret for the application to use for access to authz and authn data."
  value = azuread_application_password.this.value
}

output "tenant_id" {
  description = "The Azure tenant where the application is defined."
  value = data.azuread_client_config.current.tenant_id
}

output "app_role_ids" {
  description = "A map from app role values to the associated UUIDs."
  value = azuread_application.this.app_role_ids
}
