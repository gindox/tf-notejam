# Azure SQL

resource "azurerm_sql_server" "sql" {
  name                         = local.azuresqlname
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  version                      = "12.0"
  administrator_login          = var.sqlsrvadmin
  administrator_login_password = random_password.sqlsrvadmin.result
}

resource "azurerm_sql_firewall_rule" "azresource" {
  name                = "AllowAzureResources"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
