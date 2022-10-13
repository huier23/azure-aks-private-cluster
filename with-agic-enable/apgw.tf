resource "azurerm_public_ip" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.pip-apgw
  resource_group_name = azurerm_resource_group.external-aks.name
  location            = azurerm_resource_group.external-aks.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = var.tags
}

resource "azurerm_application_gateway" "external-aks" {
  provider = azurerm.YOURSUBSCRIPTION
  name                = var.apgw
  resource_group_name = azurerm_resource_group.external-aks.name
  location            = azurerm_resource_group.external-aks.location
  
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "apgw-gateway-ip-config"
    # subnet_id = azurerm_subnet.front-external-aks.id
    subnet_id = azurerm_virtual_network.external-aks.subnet.*.id[1]
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "Public"
    public_ip_address_id = azurerm_public_ip.external-aks.id
  }

  backend_address_pool {
    name = var.backend-address-pool
    # ip_addresses = ["10.20.20.7"]
  }

  backend_http_settings {
    name                  = var.http-setting-name
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener-name
    frontend_ip_configuration_name = "Public"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request-routing-rule-name
    rule_type                  = "Basic"
    http_listener_name         = var.listener-name
    backend_address_pool_name  = var.backend-address-pool
    backend_http_settings_name = var.http-setting-name
    priority                   = 2
  }
  tags = var.tags
  
  depends_on = [
    azurerm_virtual_network.external-aks,
    azurerm_public_ip.external-aks,
  ]
}