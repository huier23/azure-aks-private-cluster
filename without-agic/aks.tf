# Create User Assigned Identity for AKS to access private dns
resource "azurerm_user_assigned_identity" "internal-aks" {
  provider = azurerm.AZRCorpARMP
  name                = "id-${var.aks}"
  resource_group_name = azurerm_resource_group.internal-aks.name
  location            = azurerm_resource_group.internal-aks.location
  tags = var.tags
}
# Assigns a given Principal (User or Group) to a given Role
resource "azurerm_role_assignment" "netcontributor" {
  provider = azurerm.AZRCorpARMP
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.internal-aks.id
  principal_id         = azurerm_user_assigned_identity.internal-aks.principal_id
  depends_on           = [
    azurerm_virtual_network.internal-aks,
    azurerm_user_assigned_identity.internal-aks
  ]
}
# Get pre-provisioned private dns zone info
data "azurerm_private_dns_zone" "internal-aks" {
  provider = azurerm.AZRCorpCAFCONNP
  name                  = "privatelink.${var.location}.${var.private-dns-zone}"
  resource_group_name   = var.private-dns-zone-rg
}
# Assigns a given Principal (User or Group) to a given Role
resource "azurerm_role_assignment" "dnscontributor" {
  provider = azurerm.AZRCorpARMP
  role_definition_name = "Private DNS Zone Contributor"
  scope                = data.azurerm_private_dns_zone.internal-aks.id
  principal_id         = azurerm_user_assigned_identity.internal-aks.principal_id 
  depends_on           = [
    azurerm_user_assigned_identity.internal-aks
  ]
}
# Create AKS cluster
resource "azurerm_kubernetes_cluster" "internal-aks" {
  provider = azurerm.AZRCorpARMP
  name                = var.aks
  location            = azurerm_resource_group.internal-aks.location
  resource_group_name = azurerm_resource_group.internal-aks.name
  dns_prefix          = var.aks
  sku_tier            = "Paid" # API server SLA
  private_cluster_enabled = true
  private_dns_zone_id = data.azurerm_private_dns_zone.internal-aks.id

  # System node pool
  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = var.vm-size
    vnet_subnet_id = azurerm_virtual_network.internal-aks.subnet.*.id[0]
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.internal-aks.id
    ]
  }
  tags = var.tags
  depends_on = [
   azurerm_virtual_network.internal-aks,
   azurerm_role_assignment.dnscontributor,
   azurerm_role_assignment.netcontributor
  ]
}


# Cretae agent pool for AKS cluster
resource "azurerm_kubernetes_cluster_node_pool" "linux-node-pool" {
  provider = azurerm.AZRCorpARMP
  name                  = "${var.agentpool}"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.internal-aks.id
  vm_size               = var.agent-vm-size
  vnet_subnet_id        = azurerm_virtual_network.internal-aks.subnet.*.id[0]
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
    azurerm_kubernetes_cluster.internal-aks
  ]
}
