module "aci-devops-agent" {
  source                  = "../../"
  enable_vnet_integration = false
  linux_agents_configuration = {
    agent_name_prefix = "linuxagent-${var.random_suffix}"
    count             = var.agents_count
    docker_image      = var.agent_docker_image
    docker_tag        = var.agent_docker_tag
    agent_pool_name   = var.azure_devops_pool_name
  }
  resource_group_name                = "rg-terraform-azure-devops-agents-e2e-tests-${var.random_suffix}"
  location                           = var.location
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}