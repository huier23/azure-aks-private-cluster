variable "location" {
  default = "southeastasia"
}
variable "rg" {
  default = "rg-external-aks"
}
variable "nsg-apgw" {
  default = "nsg-snet-apgw-external-aks"
}
variable "nsg-aks" {
  default = "nsg-snet-aks-external-aks"
}
variable "vnet" {
  default = "vnet-aks-external-aks"
}
variable "subnet-apgw" {
  default = "snet-apgw-external-aks"
}
variable "subnet-aks" {
  default = "snet-aks-external-aks"
}
variable "udr" {
  default = "rt-aks-external-aks"
}


variable "pip-apgw" {
  default = "pip-apgw-external-aks"
}
variable "apgw" {
  default = "apgw-external-aks"
}
variable "backend-address-pool" {
  default = "aks-external-aks"
}
variable "http-setting-name" {
  default = "aks-external-aks"
}
variable "listener-name" {
  default = "aks-external-aks"
}
variable "request-routing-rule-name" {
 default = "aks-external-aks" 
}



variable "private-dns-zone" {
  default = "azmk8s.io"
}
variable "private-dns-zone-rg" {
  default = "rg-central-dns"
}
variable "aks" {
  default = "aks-external-aks"
}
variable "k8s-version" {
  default = "1.24.3"
}
variable "vm-size" {
  # default = "B_Standard_B1ms"
  default = "Standard_D2s_v4"
}
variable "agentpool" {
  default = "agentpool"
}
variable "agent-vm-size" {
  default = "Standard_D2s_v4"
}
variable "resource-count" {
  default = 1
}

variable "tags" {
  type    =  map(string)
  default = { 
    app     = "demo",
    env     = "dev",
    }
}