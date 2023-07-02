output "application_id" {
  value = azuread_application.this.application_id
}

output "client_secret" {
  value = azuread_application_password.this.value
}

output "tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}
