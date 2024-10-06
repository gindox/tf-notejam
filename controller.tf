resource "azurerm_public_ip" "pipcontroller" {
  name                = "pipcontroller"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "controller" {
  name                = "nsg-controller"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_network_security_rule" "admincenter" {
  name                        = "AdminCenter"
  network_security_group_name = azurerm_network_security_group.controller.name
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6516"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  network_security_group_name = azurerm_network_security_group.controller.name
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_interface_security_group_association" "controller" {
  network_interface_id      = azurerm_network_interface.controllereth0.id
  network_security_group_id = azurerm_network_security_group.controller.id
}

resource "azurerm_network_interface" "controllereth0" {
  name                = "controller-eth0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.control.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.0.4"
    public_ip_address_id          = azurerm_public_ip.pipcontroller.id
  }
}

resource "azurerm_windows_virtual_machine" "controller" {
  name                = "controller"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2als_v2"
  admin_username      = var.windowsadminuser
  admin_password      = random_password.adminpass.result
  network_interface_ids = [
    azurerm_network_interface.controllereth0.id,
  ]

  boot_diagnostics {}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-core-smalldisk-g2"
    version   = "latest"
  }
}


resource "azurerm_virtual_machine_extension" "controllerconfig" {
  name                       = "controllerconfig"
  virtual_machine_id         = azurerm_windows_virtual_machine.controller.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true


  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./controller.ps1 -adminpass \"${random_password.adminpass.result}\" -domainName \"${var.domainname}\" -netBIOSName \"${var.netbiosname}\"; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/gindox/tf-notejam/master/scripts/controller.ps1"
        ]
    }
  SETTINGS
}


resource "random_integer" "salt1" {
  min = 1111111111
  max = 9999999999

}

resource "random_integer" "salt2" {
  min = 1111111111
  max = 9999999999

}


resource "azurerm_virtual_machine_extension" "admincenter" {
  name                = "AdminCenter"
  virtual_machine_id         = azurerm_windows_virtual_machine.controller.id
  publisher = "Microsoft.AdminCenter"
  type = "AdminCenter"
  type_handler_version = "0.0"
  auto_upgrade_minor_version = true

  depends_on = [ 
    azurerm_virtual_machine_extension.controllerconfig
   ]

   settings = <<SETTINGS
    {
        "port": "6516",
        "salt": "${random_integer.salt1.result}${random_integer.salt2.result}",
        "cspFrameAncestors": [
            "https://portal.azure.com",
            "https://*.hosting.portal.azure.net",
            "https://localhost:1340"
        ],
        "corsOrigins": [
            "https://portal.azure.com",
            "https://waconazure.com"
        ]
    }
SETTINGS
  
}

