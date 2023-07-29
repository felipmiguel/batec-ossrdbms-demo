output "database_url" {
  value       = "${azurerm_mysql_flexible_server.database.name}.mysql.database.azure.com:3306/${azurerm_mysql_flexible_database.database.name}"
  description = "The MySQL server URL."
}

output "database_username" {
  value       = azurerm_mysql_flexible_server_active_directory_administrator.aad_admin.login
  description = "The MySQL server user name."
}
