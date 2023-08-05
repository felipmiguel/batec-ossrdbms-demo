output "resource_group" {
  value       = azurerm_resource_group.main.name
  description = "The resource group."
}

output "pgsql_server_fqdn" {
  value       = module.pgsql_database.database_fqdn
  description = "Postgresql Database server url"
}

output "pgsql_server_name" {
  value       = module.pgsql_database.database_server_name
  description = "Postgresql Database server url"
}

output "pgsql_user_name" {
  value       = module.pgsql_database.database_username
  description = "The PostgreSQL user name"
}

output "mysql_server_name" {
  value       = module.mysql_database.database_server_name
  description = "MySql Database server url"
}

output "mysql_server_fqdn" {
  value       = module.mysql_database.database_fqdn
  description = "MySql Database server url"
}

output "mysql_user_name" {
  value       = module.mysql_database.database_username
  description = "The MySql user name"
}

output "container_registry_name" {
  value       = module.application.container_registry_name
  description = "The Docker Container Registry name."
}

output "container_apps_identity" {
  value       = module.application.container_apps_identity
  description = "The Managed Identity identifier assigned to container apps"
}

output "mysql_database_name" {
  value       = module.mysql_database.database_name
  description = "The MySql database name"
}

output "pgsql_database_name" {
  value       = module.pgsql_database.database_name
  description = "The PostgreSQL database name"
}
 
output "msi_database_login_name" {
  value = module.application.database_login_name
}
