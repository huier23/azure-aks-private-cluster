terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.23.0"
    }
  }
}
# Manage Identity enable here or use serivce principle
provider "azurerm" {
  alias           = "YOURSUBSCRIPTION"
  use_msi = true
  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
  features {}
}
# Create Resource Group
resource "azurerm_resource_group" "internal-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name     = var.rg
  location = var.location
  tags = var.tags
}

# Create Network Security Group for Virtual Network
resource "azurerm_network_security_group" "internal-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                         = var.nsg
  location                     = azurerm_resource_group.internal-aks.location
  resource_group_name          = azurerm_resource_group.internal-aks.name
  tags                         = var.tags
}

# Create Virtual Network
resource "azurerm_virtual_network" "internal-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.vnet
  location            = azurerm_resource_group.internal-aks.location
  resource_group_name = azurerm_resource_group.internal-aks.name
  address_space       = ["10.20.5.0/24"]
  subnet {
    name           = var.subnet
    address_prefix =  "10.20.5.0/24"
    security_group = azurerm_network_security_group.internal-aks.id
  }
  tags = var.tags
  depends_on        = [
    azurerm_network_security_group.internal-aks,
  ]
}

# # Create Subnet of Virtual Network
# resource "azurerm_subnet" "internal-aks" {
#   provider = azurerm.YOURSUBSCRIPTION
#   name           = var.subnet
#   virtual_network_name = azurerm_virtual_network.internal-aks.name
#   resource_group_name = azurerm_resource_group.internal-aks.name
#   address_prefixes = ["10.20.5.0/24"]
# }

# Link vnet with pre-provisioned private DNS
resource "azurerm_private_dns_zone_virtual_network_link" "internal-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                  = var.vnet
  private_dns_zone_name = "privatelink.${var.location}.${var.private-dns-zone}"
  resource_group_name   = var.private-dns-zone-rg
  virtual_network_id    = azurerm_virtual_network.internal-aks.id
  # registration_enabled  = true
}