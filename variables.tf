/*
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
*/


locals {
    rgname = "rg-notejam-prod-${random_string.suffix.result}"
}

variable "location" {
    default = "northeurope"
}


variable "windowsadminuser" {
  default = "localadmin"
}

variable "domainname" {
  default = "notejam.local"
}

variable "netbiosname" {
  default = "notejam"
}

variable "hubvnet" {
  default = "vnet-northeu-notejam-prod"
}

variable "sqlsrvadmin" {
  default = "sqlsrvadmin"
}

locals  {
  azuresqlname = "sqlnotejamprod-${random_string.suffix.result}"
}

locals  {
  keyvaultname = "kv-hubprod-${random_string.suffix.result}"
}

variable "dockerPackageURL" {
  default = "ghcr.io/gindox/notejamnano/notejamnano:ltsc2022"
}