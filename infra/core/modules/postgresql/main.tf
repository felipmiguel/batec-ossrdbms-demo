terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.24"
    }
  }
}

locals {
  feature_flags = {
    high_available_type = var.high_availability ? ["ZoneRedundant"] : []
  }
}

data "azurerm_client_config" "current_client" {
}

resource "azurecaf_name" "postgresql_server" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server"
  random_length = 3
  suffixes      = [var.environment]
}

resource "azurerm_postgresql_flexible_server" "database" {
  name                = azurecaf_name.postgresql_server.result
  resource_group_name = var.resource_group
  location            = var.location

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current_client.tenant_id
  }

  sku_name                     = "B_Standard_B1ms"
  storage_mb                   = 32768
  backup_retention_days        = 7
  version                      = "13"
  geo_redundant_backup_enabled = false
  dynamic "high_availability" {
    for_each = local.feature_flags.high_available_type
    content {
      mode = high_availability.value
    }
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  lifecycle {
    ignore_changes = [zone, high_availability.0.standby_availability_zone]
  }
}

# Assuming that current user will be the AAD admin of the server
data "azuread_user" "aad_admin" {
  object_id = data.azurerm_client_config.current_client.object_id
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "aad_admin" {
  server_name         = azurerm_postgresql_flexible_server.database.name
  resource_group_name = var.resource_group
  tenant_id           = data.azurerm_client_config.current_client.tenant_id
  object_id           = data.azurerm_client_config.current_client.object_id
  principal_name      = data.azuread_user.aad_admin.user_principal_name
  principal_type      = "User"
}

resource "azurecaf_name" "postgresql_database" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server_database"
  suffixes      = [var.environment]
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = azurecaf_name.postgresql_database.result
  server_id = azurerm_postgresql_flexible_server.database.id
  charset   = "utf8"
  collation = "en_US.utf8"
}

resource "azurecaf_name" "postgresql_firewall_rule" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server_firewall_rule"
  suffixes      = [var.environment]
}

# This rule is to enable the 'Allow access to Azure services' checkbox
resource "azurerm_postgresql_flexible_server_firewall_rule" "database" {
  name             = azurecaf_name.postgresql_firewall_rule.result
  server_id        = azurerm_postgresql_flexible_server.database.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# This rule is to enable the access from agent IP
resource "azurecaf_name" "postgresql_firewall_rule_allow_iac_machine" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server_firewall_rule"
  suffixes      = [var.environment, "iac"]
}

data "http" "myip" {
  url = "http://whatismyip.akamai.com"
}

locals {
  myip = chomp(data.http.myip.response_body)
}

# This rule is to enable current machine
resource "azurerm_postgresql_flexible_server_firewall_rule" "rule_allow_iac_machine" {
  name             = azurecaf_name.postgresql_firewall_rule_allow_iac_machine.result
  server_id        = azurerm_postgresql_flexible_server.database.id
  start_ip_address = local.myip
  end_ip_address   = local.myip
}
