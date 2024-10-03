resource "azurerm_availability_set" "computeavset" {
  name                         = "computeavset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}


resource "azurerm_network_interface" "compute01eth0" {
  name                = "compute01eth0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "compute01eth0"
    subnet_id                     = azurerm_subnet.compute.id
    private_ip_address_allocation = "Dynamic"
  }
}



resource "azurerm_windows_virtual_machine" "compute01" {
  name                = "compute01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ats_v2"
  availability_set_id = azurerm_availability_set.computeavset.id
  admin_username      = var.windowsadminuser
  admin_password      = random_password.adminpass.result
  network_interface_ids = [
    azurerm_network_interface.compute01eth0.id,
  ]
  boot_diagnostics {}
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "23h2-datacenter-core-g2"
    version   = "latest"
  }
}


resource "azurerm_network_interface" "compute02eth0" {
  name                = "compute02eth0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "compute02eth0"
    subnet_id                     = azurerm_subnet.compute.id
    private_ip_address_allocation = "Dynamic"
  }
}



resource "azurerm_windows_virtual_machine" "compute02" {
  name                = "compute02"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ats_v2"
  availability_set_id = azurerm_availability_set.computeavset.id
  admin_username      = var.windowsadminuser
  admin_password      = random_password.adminpass.result
  network_interface_ids = [
    azurerm_network_interface.compute02eth0.id,
  ]
  boot_diagnostics {}
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "23h2-datacenter-core-g2"
    version   = "latest"
  }
}


# wait for the dc to wake up
resource "time_sleep" "wait" {
  depends_on = [
    azurerm_virtual_machine_extension.controllerconfig
  ]

  create_duration = "480s"
}

resource "azurerm_virtual_machine_extension" "compute01conf" {
  name                       = "compute01conf"
  virtual_machine_id         = azurerm_windows_virtual_machine.compute01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  depends_on = [
    time_sleep.wait
  ]

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./compute.ps1 -instrumentationkey \"${azurerm_application_insights.apm.instrumentation_key}\" -adminpass \"${random_password.adminpass.result}\" -domainName \"${var.domainname}\" -netBIOSName \"${var.netbiosname}\"; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/gindox/tf-notejam/master/scripts/compute.ps1"
        ]
    }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "compute02conf" {
  name                       = "compute02conf"
  virtual_machine_id         = azurerm_windows_virtual_machine.compute02.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  depends_on = [
    time_sleep.wait
  ]

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./compute.ps1 -instrumentationkey \"${azurerm_application_insights.apm.instrumentation_key}\" -adminpass \"${random_password.adminpass.result}\" -domainName \"${var.domainname}\" -dockerPackageURL \"${var.dockerPackageURL}\" -netBIOSName \"${var.netbiosname}\"; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/gindox/tf-notejam/master/scripts/compute.ps1"
        ]
    }
  SETTINGS
}



resource "azurerm_log_analytics_workspace" "oms" {
  name                = "oms-notejamprod01-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 32         
}



resource "azurerm_virtual_machine_extension" "agent01" {

  name                       = "MicrosoftMonitoringAgent"
  
  virtual_machine_id       = azurerm_windows_virtual_machine.compute01.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_virtual_machine_extension.compute01conf
  ]
  settings = <<SETTINGS
        {  
          "workspaceId": "${azurerm_log_analytics_workspace.oms.workspace_id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${azurerm_log_analytics_workspace.oms.primary_shared_key}"
        }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "agent02" {

  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id       = azurerm_windows_virtual_machine.compute02.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_virtual_machine_extension.compute02conf
  ]
  settings = <<SETTINGS
        {  
          "workspaceId": "${azurerm_log_analytics_workspace.oms.workspace_id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${azurerm_log_analytics_workspace.oms.primary_shared_key}"
        }
  PROTECTED_SETTINGS
}


#DependencyAgent
resource "azurerm_virtual_machine_extension" "dagent01" {

  name                       = "DependencyAgentWindows"
  
  virtual_machine_id       = azurerm_windows_virtual_machine.compute01.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_virtual_machine_extension.compute01conf
  ]
  settings = <<SETTINGS
        {  
          "workspaceId": "${azurerm_log_analytics_workspace.oms.workspace_id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${azurerm_log_analytics_workspace.oms.primary_shared_key}"
        }
  PROTECTED_SETTINGS
}

#DependencyAgent
resource "azurerm_virtual_machine_extension" "dagent02" {

  name                       = "DependencyAgentWindows"
  
  virtual_machine_id       = azurerm_windows_virtual_machine.compute02.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_virtual_machine_extension.compute02conf
  ]
  settings = <<SETTINGS
        {  
          "workspaceId": "${azurerm_log_analytics_workspace.oms.workspace_id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${azurerm_log_analytics_workspace.oms.primary_shared_key}"
        }
  PROTECTED_SETTINGS
}



resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.oms.id
  workspace_name        = azurerm_log_analytics_workspace.oms.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}
