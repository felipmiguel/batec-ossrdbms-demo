variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "pgsql_connection_string" {
  type        = string
  description = "The connection string to postgresql database"  
}

variable "mysql_connection_string" {
  type        = string
  description = "The connection string to mysql database"  
}