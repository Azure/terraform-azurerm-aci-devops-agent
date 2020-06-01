module "aci-devops-agent" {
  source                  = "../../"
  enable_vnet_integration = false
  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    agent_pool_name   = var.azure_devops_pool_name
  }
  resource_group_name                = "rg-linux-devops-agents"
  location                           = "westeurope"
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}