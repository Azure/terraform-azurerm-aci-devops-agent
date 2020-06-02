module "aci-devops-agent" {
  source                  = "../../../"
  enable_vnet_integration = false
  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    agent_pool_name   = var.linux_azure_devops_pool_name
    cpu               = 1
    memory            = 4
  }
  windows_agents_configuration = {
    agent_name_prefix = "windows-agent"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-win"
    agent_pool_name   = var.windows_azure_devops_pool_name
    cpu               = 1
    memory            = 4
  }
  resource_group_name                = "rg-aci-devops-agents-we"
  location                           = "westeurope"
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}