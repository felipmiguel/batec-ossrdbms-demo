output "database_fqdn" {
  value       = azurerm_postgresql_flexible_server.database.fqdn
  description = "The PostgreSQL server FQDN."
}

output "database_server_name" {
  value       = azurerm_postgresql_flexible_server.database.name
  description = "The PostgreSQL server name."
}

output "database_name" {
  value       = azurerm_postgresql_flexible_server_database.database.name
  description = "The PostgreSQL database name."
}

output "database_username" {
  value       = azurerm_postgresql_flexible_server_active_directory_administrator.aad_admin.principal_name
  description = "The PostgreSQL server user name."
}

output "database_dotnet_connection_string" {
  value= "Server=${azurerm_postgresql_flexible_server.database.fqdn};Database=${azurerm_postgresql_flexible_server_database.database.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true"
}