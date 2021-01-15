module "aci-devops-agent" {
  source                  = "../../../"
  enable_vnet_integration = false
  create_resource_group   = true
  linux_agents_configuration = {
    agent_name_prefix = "linux-agent-${var.random_suffix}"
    count             = 2,
    docker_image      = var.linux_agent_docker_image
    docker_tag        = var.linux_agent_docker_tag
    agent_pool_name   = var.linux_azure_devops_pool_name
    cpu               = 1
    memory            = 4
  }
  windows_agents_configuration = {
    agent_name_prefix = "windows-agent-${var.random_suffix}"
    count             = 2,
    docker_image      = var.windows_agent_docker_image
    docker_tag        = var.windows_agent_docker_tag
    agent_pool_name   = var.windows_azure_devops_pool_name
    cpu               = 1
    memory            = 4
  }
  resource_group_name                = "rg-terraform-azure-devops-agents-e2e-tests-${var.random_suffix}"
  location                           = var.location
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}