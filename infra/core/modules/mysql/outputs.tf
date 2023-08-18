output "database_fqdn" {
  value       = azurerm_mysql_flexible_server.database.fqdn
  description = "The MySQL server FQDN."
}

output "database_server_name" {
  value       = azurerm_mysql_flexible_server.database.name
  description = "The MySQL server name."
}

output "database_name" {
  value       = azurerm_mysql_flexible_database.database.name
  description = "The MySQL database name."
}

output "database_username" {
  value       = azurerm_mysql_flexible_server_active_directory_administrator.aad_admin.login
  description = "The MySQL server user name."
}

output "database_dotnet_connection_string" {
  value= "Server=${azurerm_mysql_flexible_server.database.fqdn};Database=${azurerm_mysql_flexible_database.database.name};SslMode=Required"
}
