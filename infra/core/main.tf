terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.67.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
}

resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [local.environment]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.16.0"
  }
}

module "application" {
  source           = "./modules/container-apps"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  pgsql_database_url      = module.pgsql_database.database_url
  pgsql_database_username = module.pgsql_database.database_username

  mysql_database_url      = module.mysql_database.database_url
  mysql_database_username = module.mysql_database.database_username
}

module "pgsql_database" {
  source            = "./modules/postgresql"
  resource_group    = azurerm_resource_group.main.name
  application_name  = var.application_name
  environment       = local.environment
  location          = var.location
  high_availability = false
}

module "mysql_database" {
  source           = "./modules/mysql"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}
