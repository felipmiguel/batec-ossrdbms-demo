output "database_url" {
  value       = "${azurerm_postgresql_flexible_server.database.fqdn}:5432/${azurerm_postgresql_flexible_server_database.database.name}"
  description = "The PostgreSQL server URL."
}

output "database_username" {
  value       = azurerm_postgresql_flexible_server_active_directory_administrator.aad_admin.principal_name
  description = "The PostgreSQL server user name."
}