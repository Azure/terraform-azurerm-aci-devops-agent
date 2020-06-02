resource "azurerm_resource_group" "vnet-rg" {
  name     = "rg-aci-devops-network-${var.random_suffix}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aci-devops-${var.random_suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
}

resource "azurerm_subnet" "aci-subnet" {
  name                 = "aci-subnet-${var.random_suffix}"
  resource_group_name  = azurerm_resource_group.vnet-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "acidelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
  }
}

module "aci-devops-agent" {
  source                   = "../../../"
  enable_vnet_integration  = true
  vnet_resource_group_name = azurerm_resource_group.vnet-rg.name
  vnet_name                = azurerm_virtual_network.vnet.name
  subnet_name              = azurerm_subnet.aci-subnet.name
  linux_agents_configuration = {
    agent_name_prefix = "linuxagent-${var.random_suffix}"
    count             = var.agents_count
    docker_image      = var.agent_docker_image
    docker_tag        = var.agent_docker_tag
    agent_pool_name   = var.azure_devops_pool_name
    cpu               = 1
    memory            = 4
  }
  resource_group_name                = "rg-terraform-azure-devops-agents-e2e-tests-${var.random_suffix}"
  location                           = var.location
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}