# Create User Assigned Identity for AKS to another resource
resource "azurerm_user_assigned_identity" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = "id-network-aks-public-southeastasia-001"
  resource_group_name = azurerm_resource_group.external-aks.name
  location            = azurerm_resource_group.external-aks.location
  tags = var.tags
}
# Assigns a given Principal (User or Group) to a given Role
resource "azurerm_role_assignment" "netcontributor" {
  provider = azurerm.YOURSUBSCRIPTION
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.external-aks.id
  principal_id         = azurerm_user_assigned_identity.external-aks.principal_id
  depends_on           = [
    azurerm_virtual_network.external-aks,
    azurerm_user_assigned_identity.external-aks
  ]
}
# Assigns a given Principal (User or Group) to a given Role
resource "azurerm_role_assignment" "udrcontributor" {
  provider = azurerm.YOURSUBSCRIPTION
  role_definition_name = "Network Contributor"
  scope                = azurerm_route_table.external-aks.id
  principal_id         = azurerm_user_assigned_identity.external-aks.principal_id 
  depends_on           = [
    azurerm_route_table.external-aks,
    azurerm_user_assigned_identity.external-aks,
  ]
}
# Get pre-provisioned private dns zone info
data "azurerm_private_dns_zone" "external-aks" {
  provider = azurerm.AZRCorpCAFCONNP
  name                  = "privatelink.${var.location}.${var.private-dns-zone}"
  resource_group_name   = var.private-dns-zone-rg
}
# Assigns a given Principal (User or Group) to a given Role
resource "azurerm_role_assignment" "dnscontributor" {
  provider = azurerm.YOURSUBSCRIPTION
  role_definition_name = "Private DNS Zone Contributor"
  scope                = data.azurerm_private_dns_zone.external-aks.id
  principal_id         = azurerm_user_assigned_identity.external-aks.principal_id 
  depends_on           = [
    azurerm_user_assigned_identity.external-aks
  ]
}
# Create AKS cluster
resource "azurerm_kubernetes_cluster" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.aks
  location            = azurerm_resource_group.external-aks.location
  resource_group_name = azurerm_resource_group.external-aks.name
  dns_prefix          = var.aks
  sku_tier            = "Paid" # API server SLA
  private_cluster_enabled = true
  private_dns_zone_id = data.azurerm_private_dns_zone.external-aks.id

  # Enable AGIC and config pre-provisioned APGW
  ingress_application_gateway {
    gateway_id        = azurerm_application_gateway.external-aks.id
  }

  # System node pool
  default_node_pool {
    name       = "system"
    node_count = 2
    vm_size    = var.vm-size
    vnet_subnet_id = azurerm_virtual_network.external-aks.subnet.*.id[0]
  }
  # Force AKS to use custom user assigned identity
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.external-aks.id
    ]
  }

  tags = var.tags
  depends_on = [
   azurerm_virtual_network.external-aks,
   azurerm_role_assignment.dnscontributor,
   azurerm_role_assignment.netcontributor,
   azurerm_role_assignment.udrcontributor,
   azurerm_application_gateway.external-aks
  ]
}


# Cretae agent pool for AKS cluster
resource "azurerm_kubernetes_cluster_node_pool" "linux-node-pool" {
  provider = azurerm.YOURSUBSCRIPTION
  count = var.resource-count  
  name                  = "${var.agentpool}${count.index}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.external-aks.id
  vm_size               = var.agent-vm-size
  vnet_subnet_id        = azurerm_virtual_network.external-aks.subnet.*.id[0]
  os_type               = "Linux"
  node_count            = 1
  max_pods              = 100
  os_disk_size_gb       = 128
  enable_auto_scaling   = true
  enable_host_encryption= false
  enable_node_public_ip = false
  fips_enabled          = false
  node_taints           = []
  max_count             = 5
  min_count             = 1
  depends_on            = [
    azurerm_kubernetes_cluster.external-aks
  ]
}

# Assigns a READER role of resource group and CONTRIBUTOR role of APGW for ingress-apgw user assigned identity which created by system.
resource "azurerm_role_assignment" "rgreader" {
  provider = azurerm.YOURSUBSCRIPTION
  role_definition_name = "Reader"
  scope                = azurerm_resource_group.external-aks.id
  principal_id         = azurerm_kubernetes_cluster.external-aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [
    azurerm_resource_group.external-aks,
    azurerm_kubernetes_cluster.external-aks,
  ]
}
resource "azurerm_role_assignment" "apgwcontributor" {
  provider = azurerm.YOURSUBSCRIPTION
  role_definition_name = "Contributor"
  scope                = azurerm_application_gateway.external-aks.id
  principal_id         = azurerm_kubernetes_cluster.external-aks.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [
    azurerm_application_gateway.external-aks,
    azurerm_kubernetes_cluster.external-aks,
  ]
}
