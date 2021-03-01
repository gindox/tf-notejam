resource "azurerm_public_ip" "piplbnotejamj231" {
  name                = "piplbnotejamj231"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Basic"
}

resource "azurerm_lb" "lb" {
  name                = "lbnotejamj231"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "Basic"
  depends_on = [ 
    azurerm_windows_virtual_machine.compute01,
    azurerm_windows_virtual_machine.compute02
   ]

  frontend_ip_configuration {
    name                 = "piplbnotejamj231"
    public_ip_address_id = azurerm_public_ip.piplbnotejamj231.id
  }
}

resource "azurerm_lb_backend_address_pool" "dockerbackend" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "dockerbackend"
}

resource "azurerm_lb_probe" "http" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "http"
  port                = 80
  interval_in_seconds = 10
  number_of_probes    = 6
}

resource "azurerm_lb_rule" "http" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "piplbnotejamj231"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.dockerbackend.id
  probe_id                       = azurerm_lb_probe.http.id
  idle_timeout_in_minutes        = 20
}


resource "azurerm_network_interface_backend_address_pool_association" "compute01" {
  network_interface_id    = azurerm_network_interface.compute01eth0.id
  ip_configuration_name   = "compute01eth0"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dockerbackend.id
}


resource "azurerm_network_interface_backend_address_pool_association" "compute02" {
  network_interface_id    = azurerm_network_interface.compute02eth0.id
  ip_configuration_name   = "compute02eth0"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dockerbackend.id
}


