# Provision Private Azure Kubernetes Service Cluster
## Azure Provider
- Managed Identity
## Resource would be deployed via this script as below
### With AGIC enable: external facing application
- Resoucre Group
- Virtual Network (10.20.3.0/23)
- Network Security *2 for subnet
- APGW Subnet (10.20.3.0/24)
- AKS Subnet (10.20.4.0/24)
- Custom route table
- Application Gateway
- Management Identity for AKS for assigment with
    - Network Contributor -> VNET
    - Network Contributor -> Private DNS Zone
    - Contributor -> customer Route Table
- Private AKS cluster
- User agent pool *2
- Add role assignment for auto-provision AGIC Management Idenetity
    - Read -> AKS resource group
    - Contributor -> APGW
### Without AGIC enable: 
- Resoucre Group
- Virtual Network (10.20.5.0/24)
- Network Security for subnet
- AKS Subnet (10.20.5.0/24)
- Management Identity for AKS for assigment with
    - Network Contributor -> VNET
    - Network Contributor -> Private DNS Zone
- Private AKS cluster
- User agent pool *1
### Testing
- `k8s/hello-world-asp.yaml` for AGIC testing
- `k8s/internal-lb.yaml` and `k8s/azure-vote-all-in-one.yaml` for internal facing AKS testing (or your own ingress service)