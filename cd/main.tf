## Azure provider
provider "azurerm" {
  version = "~>1.32.0"
}

terraform {
    backend "azurerm" {
  }
}

## Resource Group
resource "azurerm_resource_group" "this" {
  name     = "${var.app_name}-${var.env_name}"
  location = "${var.az_location}"

  tags = {
    app = "${var.app_name}"
    environment = "${var.env_name}"
    department = "${var.department}"
  }
}

## Database
resource "azurerm_sql_server" "this" {
  name                         = "${var.app_name}-${var.env_name}"
  resource_group_name          = "${azurerm_resource_group.this.name}"
  location                     = "${azurerm_resource_group.this.location}"
  version                      = "12.0"
  administrator_login          = "${var.db_admin_username}"
  administrator_login_password = "${var.db_admin_password}"

  tags = {
    app = "${var.app_name}"
    environment = "${var.env_name}"
    department = "${var.department}"
  }
}

resource "azurerm_sql_database" "this" {
  name                             = "${var.app_name}-${var.env_name}"
  resource_group_name              = "${azurerm_resource_group.this.name}"
  location                         = "${azurerm_resource_group.this.location}"
  server_name                      = "${azurerm_sql_server.this.name}"
  edition                          = "Standard"
  requested_service_objective_name = "S0"

  tags = {
    app = "${var.app_name}"
    environment = "${var.env_name}"
    department = "${var.department}"
  }
}

#resource "azurerm_sql_firewall_rule" "this" {
#  name                = "${azurerm_sql_server.this.name}-fwrules"
#  resource_group_name = "${azurerm_resource_group.this.name}"
#  server_name         = "${azurerm_sql_server.this.name}"
#  start_ip_address    = "${var.start_ip_address}"
#  end_ip_address      = "${var.end_ip_address}"
#}

## App Service
resource "azurerm_app_service_plan" "this" {
  name                = "${var.app_name}-appserviceplan-${var.env_name}"
  location            = "${azurerm_resource_group.this.location}"
  resource_group_name = "${azurerm_resource_group.this.name}"
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }

  tags = {
    app = "${var.app_name}"
    environment = "${var.env_name}"
    department = "${var.department}"
  }
}

resource "azurerm_app_service" "this" {
  name                = "${var.app_name}-${var.env_name}"
  location            = "${azurerm_resource_group.this.location}"
  resource_group_name = "${azurerm_resource_group.this.name}"
  app_service_plan_id = "${azurerm_app_service_plan.this.id}"

  site_config {
    always_on = "false"
    #cors {
    #  # Enables cross origin calls from everywhere
    #  allowed_origins = "*"
    #}
    linux_fx_version = "DOCKER|${var.az_container_registry}/${var.app_name}:latest"
    # Must set use_32_bit_worker_process to true for Free or Shared tier instances
    #use_32_bit_worker_process = "true" 
  }

  auth_settings {
    enabled = "false"
    #active_directory {
    #  client_id = ""
    #  client_secret = ""
    #}
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = "https://${var.az_container_registry}"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=tcp:${azurerm_sql_server.this.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.this.name};Persist Security Info=False;User ID=${azurerm_sql_server.this.administrator_login};Password=${azurerm_sql_server.this.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  tags = {
    app = "${var.app_name}"
    environment = "${var.env_name}"
    department = "${var.department}"
  }
}
