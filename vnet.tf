resource "azurerm_virtual_network" "hub" {
  name                = "vnet-northeu-hub"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "control" {
  name                 = "control"
  virtual_network_name = azurerm_virtual_network.hub.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.20.0.0/24"]
}


resource "azurerm_subnet" "gatewaysubnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.hub.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.20.254.0/24"]
}

resource "azurerm_virtual_network" "notejamprd01" {
  name                = "vnet-northeu-notejam-prod01"
  address_space       = ["10.14.0.0/24"]
  dns_servers         = ["10.20.0.4"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "compute" {
  name                 = "compute"
  virtual_network_name = azurerm_virtual_network.notejamprd01.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.14.0.0/26"]
}

resource "azurerm_virtual_network_peering" "peer-prod-to-hub" {
  name                         = "peer-notejamprd01-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.notejamprd01.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false # change this setting when plugging this VNET into a hub with a GW/IPSec to onprem
}

resource "azurerm_virtual_network_peering" "peer-hub-to-prod" {
  name                         = "peer-hub-to-notejamprd01"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.notejamprd01.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}
