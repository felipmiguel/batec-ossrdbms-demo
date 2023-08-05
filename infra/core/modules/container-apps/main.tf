terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.24"
    }
  }
}

locals {
  database_login_name     = var.application_name
  mysql_connection_string = "${var.mysql_connection_string};UserID=${local.database_login_name};"
  pgsql_connection_string = "${var.pgsql_connection_string};User Id=${local.database_login_name};"
}

resource "azurecaf_name" "container_registry" {
  name          = var.application_name
  resource_type = "azurerm_container_registry"
  suffixes      = [var.environment]
}

resource "azurerm_container_registry" "container_registry" {
  name                = azurecaf_name.container_registry.result
  resource_group_name = var.resource_group
  location            = var.location
  admin_enabled       = true
  sku                 = "Basic"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

resource "azurerm_role_assignment" "aca_msi_acr_pull" {
  principal_id                     = azurerm_user_assigned_identity.msi_container_app.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.container_registry.id
  skip_service_principal_aad_check = true
}

resource "azurecaf_name" "log_analytics_workspace" {
  name          = var.application_name
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.environment]
}

resource "azurerm_log_analytics_workspace" "application" {
  name                = azurecaf_name.log_analytics_workspace.result
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurecaf_name" "msi_container_app" {
  name          = var.application_name
  resource_type = "azurerm_user_assigned_identity"
  suffixes      = [var.environment]
}

resource "azurerm_user_assigned_identity" "msi_container_app" {
  name                = azurecaf_name.msi_container_app.result
  resource_group_name = var.resource_group
  location            = var.location
}

resource "azurecaf_name" "application_environment" {
  name          = var.application_name
  resource_type = "azurerm_container_app_environment"
  suffixes      = [var.environment]
}

resource "azurerm_container_app_environment" "application" {
  name                       = azurecaf_name.application_environment.result
  resource_group_name        = var.resource_group
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.application.id
}

resource "azurecaf_name" "pgsql_application" {
  name          = var.application_name
  resource_type = "azurerm_container_app"
  suffixes      = [var.environment, "pgsql"]
}

resource "azurerm_container_app" "pgsql_application" {
  name                         = azurecaf_name.pgsql_application.result
  container_app_environment_id = azurerm_container_app_environment.application.id
  resource_group_name          = var.resource_group
  revision_mode                = "Single"

  lifecycle {
    ignore_changes = [
      template.0.container["image"]
    ]
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.msi_container_app.id
    ]
  }

  registry {
    identity = azurerm_user_assigned_identity.msi_container_app.id
    server   = azurerm_container_registry.container_registry.login_server
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = azurecaf_name.pgsql_application.result
      image  = "${azurerm_container_registry.container_registry.name}.azurecr.io/todoapi:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name  = "PgSqlConnection"
        value = local.pgsql_connection_string
      }
      env {
        name  = "TargetDb"
        value = "Postgresql"
      }
      env {
        name  = "UserAssignedManagedClientId"
        value = azurerm_user_assigned_identity.msi_container_app.client_id
      }
    }
    min_replicas = 1
  }
}

resource "azurecaf_name" "mysql_application" {
  name          = var.application_name
  resource_type = "azurerm_container_app"
  suffixes      = [var.environment, "mysql"]
}

resource "azurerm_container_app" "mysql_application" {
  name                         = azurecaf_name.mysql_application.result
  container_app_environment_id = azurerm_container_app_environment.application.id
  resource_group_name          = var.resource_group
  revision_mode                = "Single"

  lifecycle {
    ignore_changes = [
      template.0.container["image"]
    ]
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.msi_container_app.id
    ]
  }

  registry {
    identity = azurerm_user_assigned_identity.msi_container_app.id
    server   = azurerm_container_registry.container_registry.login_server
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = azurecaf_name.mysql_application.result
      image  = "${azurerm_container_registry.container_registry.name}.azurecr.io/todoapi:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name  = "MySqlConnection"
        value = local.mysql_connection_string
      }
      env {
        name  = "TargetDb"
        value = "MySql"
      }
      env {
        name  = "UserAssignedManagedClientId"
        value = azurerm_user_assigned_identity.msi_container_app.client_id
      }
    }
    min_replicas = 1
  }
}
