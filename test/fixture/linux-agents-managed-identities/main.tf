locals {
  resource_group_name = "rg-terraform-azure-devops-agents-e2e-tests-${var.random_suffix}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}
resource "azurerm_user_assigned_identity" "example1" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "identity1"
}
resource "azurerm_user_assigned_identity" "example2" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name = "identity2"
}
module "aci-devops-agent" {
  source                  = "../../../"
  enable_vnet_integration = false
  create_resource_group   = false
  linux_agents_configuration = {
    agent_name_prefix = "linuxagent-${var.random_suffix}"
    count             = var.agents_count
    docker_image      = var.agent_docker_image
    docker_tag        = var.agent_docker_tag
    agent_pool_name   = var.azure_devops_pool_name
    cpu               = 1
    memory            = 4
    user_assigned_identity_ids = [azurerm_user_assigned_identity.example1.id, azurerm_user_assigned_identity.example2.id]
    use_system_assigned_identity = true
  }
  resource_group_name                = azurerm_resource_group.name
  location                           = var.location
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}