terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.24"
    }
  }
}

resource "azurecaf_name" "mysql_umi" {
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.environment, "mysql"]
}

resource "azurerm_user_assigned_identity" "mysql_umi" {
  name                = azurecaf_name.mysql_umi.result
  resource_group_name = var.resource_group
  location            = var.location
}

resource "azurecaf_name" "mysql_server" {
  name          = var.application_name
  resource_type = "azurerm_mysql_server"
  random_length = 3
  suffixes      = [var.environment]
}

resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurerm_mysql_flexible_server" "database" {
  name                = azurecaf_name.mysql_server.result
  resource_group_name = var.resource_group
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = random_password.password.result

  identity {
    identity_ids = [azurerm_user_assigned_identity.mysql_umi.id]
    type         = "UserAssigned"
  }

  sku_name                     = "B_Standard_B1s"
  version                      = "8.0.21"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  lifecycle {
    ignore_changes = [zone]
  }
}
data "azurerm_client_config" "current_client" {
}

# Assuming that current user will be the AAD admin of the server
data "azuread_user" "aad_admin" {
  object_id = data.azurerm_client_config.current_client.object_id
}

resource "azurerm_mysql_flexible_server_active_directory_administrator" "aad_admin" {
  server_id   = azurerm_mysql_flexible_server.database.id
  identity_id = azurerm_user_assigned_identity.mysql_umi.id
  login       = data.azuread_user.aad_admin.user_principal_name
  object_id   = data.azurerm_client_config.current_client.object_id
  tenant_id   = data.azurerm_client_config.current_client.tenant_id
}

resource "azurerm_mysql_flexible_database" "database" {
  name                = var.database_name
  resource_group_name = var.resource_group
  server_name         = azurerm_mysql_flexible_server.database.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
  lifecycle {
    ignore_changes = [charset, collation]
  }
}

resource "azurecaf_name" "mysql_firewall_rule" {
  name          = var.application_name
  resource_type = "azurerm_mysql_firewall_rule"
  suffixes      = [var.environment]
}

# This rule is to enable the 'Allow access to Azure services' checkbox
resource "azurerm_mysql_flexible_server_firewall_rule" "database" {
  name                = azurecaf_name.mysql_firewall_rule.result
  resource_group_name = var.resource_group
  server_name         = azurerm_mysql_flexible_server.database.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurecaf_name" "mysql_firewall_rule_allow_iac_machine" {
  name          = var.application_name
  resource_type = "azurerm_mysql_firewall_rule"
  suffixes      = [var.environment, "iac"]
}

data "http" "myip" {
  url = "http://whatismyip.akamai.com"
}

locals {
  myip = chomp(data.http.myip.response_body)
}

# This rule is to enable current machine
resource "azurerm_mysql_flexible_server_firewall_rule" "rule_allow_iac_machine" {
  name                = azurecaf_name.mysql_firewall_rule_allow_iac_machine.result
  resource_group_name = var.resource_group
  server_name         = azurerm_mysql_flexible_server.database.name
  start_ip_address    = local.myip
  end_ip_address      = local.myip
}