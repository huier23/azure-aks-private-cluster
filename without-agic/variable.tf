variable "location" {
  default = "southeastasia"
}
variable "rg" {
  default = "rg-internal-aks"
}
variable "nsg"{
  default = "nsg-internal-aks"
}
variable "vnet" {
  default = "vnet-internal-aks"
}
variable "subnet" {
  default = "snet-internal-aks"
}
variable "private-dns-zone" {
  default = "azmk8s.io"
}
variable "private-dns-zone-rg" {
  default = "rg-central-dns"
}
variable "aks" {
  default = "aks-internal-aks"
}
variable "k8s-version" {
  default = "1.24.3"
}
variable "vm-size" {
  default = "Standard_D2s_v4"
}
variable "agent-vm-size" {
  default = "Standard_D4s_v4"
}
variable "agentpool" {
  default = "dev"
}

variable "tags" {
  type    =  map(string)
  default = { 
    app     = "demo",
    env     = "dev",
    }
}