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
resource "azurerm_resource_group" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name     = var.rg
  location = var.location
  tags = var.tags
}

# Create Network Security Group for Virtual Network
resource "azurerm_network_security_group" "nsg-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                         = var.nsg-aks
  location                     = azurerm_resource_group.external-aks.location
  resource_group_name          = azurerm_resource_group.external-aks.name
  tags                         = var.tags
}
# Create Network Security Group and rule for subnet
resource "azurerm_network_security_group" "nsg-apgw" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.nsg-apgw
  location            = azurerm_resource_group.external-aks.location
  resource_group_name = azurerm_resource_group.external-aks.name
  tags                = var.tags
}
# Create Security Rule for NSG
resource "azurerm_network_security_rule" "apgw-mgmt-rule" {
  provider = azurerm.YOURSUBSCRIPTION
  name                        = "AllowAPGWManagerInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.external-aks.name
  network_security_group_name = azurerm_network_security_group.nsg-apgw.name
  depends_on = [
    azurerm_network_security_group.nsg-apgw,
  ]
}
resource "azurerm_network_security_rule" "lb-rule" {
  provider = azurerm.YOURSUBSCRIPTION
  name                        = "AllowLoadBalancerInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.external-aks.name
  network_security_group_name = azurerm_network_security_group.nsg-apgw.name
  depends_on = [
    azurerm_network_security_group.nsg-apgw,
  ]
}
resource "azurerm_network_security_rule" "http-rule" {
  provider = azurerm.YOURSUBSCRIPTION
  name                        = "AllowAnyHttpInbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.external-aks.name
  network_security_group_name = azurerm_network_security_group.nsg-apgw.name
  depends_on = [
    azurerm_network_security_group.nsg-apgw,  
  ]
}
resource "azurerm_network_security_rule" "https-rule" {
  provider = azurerm.YOURSUBSCRIPTION
  name                        = "AllowAnyHttpsInbound"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.external-aks.name
  network_security_group_name = azurerm_network_security_group.nsg-apgw.name
  depends_on = [
    azurerm_network_security_group.nsg-apgw,  
  ]
}
# Create Virtual Network
resource "azurerm_virtual_network" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.vnet
  location            = azurerm_resource_group.external-aks.location
  resource_group_name = azurerm_resource_group.external-aks.name
  address_space       = ["10.20.3.0/23"]
  subnet {
    name           = var.subnet-aks
    address_prefix =  "10.20.4.0/24"
    security_group = azurerm_network_security_group.nsg-aks.id
  }
  subnet {
    name           = var.subnet-apgw
    address_prefix =  "10.20.3.0/24"
    security_group = azurerm_network_security_group.nsg-apgw.id
  }
  tags = var.tags

  depends_on        = [
    azurerm_network_security_group.nsg-aks,
    azurerm_network_security_group.nsg-apgw,
  ]
}

# Link vnet with pre-provisioned private DNS
resource "azurerm_private_dns_zone_virtual_network_link" "external-aks" {
  provider = azurerm.AZRCorpCAFCONNP
  name                  = var.vnet
  private_dns_zone_name = "privatelink.${var.location}.${var.private-dns-zone}"
  resource_group_name   = var.private-dns-zone-rg
  virtual_network_id    = azurerm_virtual_network.external-aks.id
  # registration_enabled  = true

  depends_on            = [
    azurerm_virtual_network.external-aks
  ]
}

# Create Custom Route Table
resource "azurerm_route_table" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                          = var.udr
  location                      = azurerm_resource_group.external-aks.location
  resource_group_name           = azurerm_resource_group.external-aks.name
  disable_bgp_route_propagation = false
  tags = var.tags
}

# Associate APGW and AKS subnet to UDR
resource "azurerm_subnet_route_table_association" "external-aks-apgw" {
  provider = azurerm.YOURSUBSCRIPTION
  subnet_id      = azurerm_virtual_network.external-aks.subnet.*.id[1]
  route_table_id = azurerm_route_table.external-aks.id
  depends_on            = [
    azurerm_virtual_network.external-aks,
    azurerm_route_table.external-aks
  ]
}
resource "azurerm_subnet_route_table_association" "external-aks-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  subnet_id      = azurerm_virtual_network.external-aks.subnet.*.id[0]
  route_table_id = azurerm_route_table.external-aks.id
  depends_on            = [
    azurerm_virtual_network.external-aks,
    azurerm_route_table.external-aks
  ]
}