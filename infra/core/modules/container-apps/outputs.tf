output "container_registry_name" {
  value       = azurerm_container_registry.container_registry.name
  description = "The Docker Container Registry name generated by the Azure Cloud Adoption Framework."
}

output "container_apps_identity" {
  value       = azurerm_user_assigned_identity.msi_container_app.id
  description = "The Managed Identity assigned to container apps"
}


output "database_login_name" {
  value = local.database_login_name
}

output "container_environment_name" {
  value = azurerm_container_app_environment.application.name
}
