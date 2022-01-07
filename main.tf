terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.49.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.1.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "current" {
}

#https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password
resource "random_password" "adminpass" {
  length  = 24
  special = false
}

resource "random_password" "sqlsrvadmin" {
  length  = 24
  special = false
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name     = local.rgname
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                        = local.keyvaultname
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "get",
      "set",
      "list",
      "delete"
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_secret" "adminpass" {
  name         = "windowsadminpass"
  value        = random_password.adminpass.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "sqlsrvadmin" {
  name         = "sqlsrvadmin"
  value        = random_password.sqlsrvadmin.result
  key_vault_id = azurerm_key_vault.kv.id
}


resource "azurerm_application_insights" "apm" {
  name                = "apm-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault_secret" "instrumentationkey" {
  name         = "instrumentationkey"
  value        = azurerm_application_insights.apm.instrumentation_key
  key_vault_id = azurerm_key_vault.kv.id
}



output "lb-ip" {
  value = azurerm_public_ip.piplbnotejamj231.ip_address
}

output "controller-ip" {
  value = azurerm_public_ip.pipcontroller.ip_address
}

output "windowsadminpass" {
  value = random_password.adminpass.result
  sensitive = true
}
