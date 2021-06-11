data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  keepers = {
    id = data.azurerm_client_config.current.object_id
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-azure-devops-agents-e2e-tests-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "acr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "./build.sh"

    environment = {
      acr_name = azurerm_container_registry.acr.name
    }
    working_dir = "${path.module}/"
  }

  depends_on = [azurerm_role_assignment.acr_push]
}


module "aci-devops-agent" {
  source                  = "../../../"
  enable_vnet_integration = false
  create_resource_group   = false

  linux_agents_configuration = {
    agent_name_prefix            = "linux-agent-${random_string.suffix.result}"
    count                        = var.agents_count,
    docker_image                 = "${azurerm_container_registry.acr.login_server}/${var.linux_agent_docker_image}"
    docker_tag                   = var.linux_agent_docker_tag
    agent_pool_name              = var.linux_azure_devops_pool_name
    cpu                          = 1
    memory                       = 4
    user_assigned_identity_ids   = []
    use_system_assigned_identity = false
  }

  image_registry_credential = {
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
    server   = azurerm_container_registry.acr.login_server
  }

  resource_group_name                = azurerm_resource_group.rg.name
  location                           = azurerm_resource_group.rg.location
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
  depends_on                         = [null_resource.build]
}
