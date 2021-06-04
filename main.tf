resource "azurerm_resource_group" "rg" {
  # the resource group is created only if the flag create_resource_group is set to true
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "rg" {
  # the resource group is imported only if the flag create_resource_group is set to false
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  # the subnet is imported only enable_vnet_integration is true
  count                = var.enable_vnet_integration ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

locals {
  # umi == user managed identity, smi == system managed identity
  use_umi                    = length(var.linux_agents_configuration.user_assigned_identity_ids) > 0
  use_smi                    = var.linux_agents_configuration.use_system_assigned_identity
  identity_block_smi         = local.use_smi && !local.use_umi ? [1] : []
  identity_block_umi         = local.use_umi && !local.use_smi ? [1] : []
  identity_block_umi_and_smi = local.use_umi && local.use_smi ? [1] : []
}

# Linux Agents - deployed only if variable linux_agents_configuration.count > 0

resource "azurerm_network_profile" "linux_network_profile" {
  count               = var.enable_vnet_integration ? var.linux_agents_configuration.count : 0
  name                = "linuxnetprofile${count.index}"
  location            = var.location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  container_network_interface {
    name = "linuxnic${count.index}"

    ip_configuration {
      name      = "linuxip${count.index}"
      subnet_id = data.azurerm_subnet.subnet[0].id
    }
  }
}

resource "azurerm_container_group" "linux-container-group" {
  count               = var.linux_agents_configuration.count
  name                = "${var.linux_agents_configuration.agent_name_prefix}-${count.index}"
  location            = var.location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  ip_address_type     = var.enable_vnet_integration ? "private" : "public"
  os_type             = "linux"
  network_profile_id  = var.enable_vnet_integration ? azurerm_network_profile.linux_network_profile[count.index].id : null

  container {
    name   = "${var.linux_agents_configuration.agent_name_prefix}-${count.index}"
    image  = "${var.linux_agents_configuration.docker_image}:${var.linux_agents_configuration.docker_tag}"
    cpu    = var.linux_agents_configuration.cpu
    memory = var.linux_agents_configuration.memory

    # this field seems to be mandatory (error happens if not there). See https://github.com/terraform-providers/terraform-provider-azurerm/issues/1697#issuecomment-608669422
    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      AZP_URL        = "https://dev.azure.com/${var.azure_devops_org_name}"
      AZP_POOL       = var.linux_agents_configuration.agent_pool_name
      AZP_AGENT_NAME = "${var.linux_agents_configuration.agent_name_prefix}-${count.index}"
    }

    secure_environment_variables = {
      AZP_TOKEN = var.azure_devops_personal_access_token
    }
  }

  # if an image registry server has been specified, then generate the image_registry_credential block.
  dynamic "image_registry_credential" {
    for_each = var.image_registry_credential.server == "" ? [] : [1]
    content {
      username = var.image_registry_credential.username
      password = var.image_registry_credential.password
      server   = var.image_registry_credential.server
    }
  }

  # identity block
  dynamic "identity" {
    for_each = local.identity_block_smi
    content {
      type = "SystemAssigned"
    }
  }
  dynamic "identity" {
    for_each = local.identity_block_umi
    content {
      type         = "UserAssigned"
      identity_ids = var.linux_agents_configuration.user_assigned_identity_ids
    }
  }
  dynamic "identity" {
    for_each = local.identity_block_umi_and_smi
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = var.linux_agents_configuration.user_assigned_identity_ids
    }
  }
}

# Windows Agents - deployed only if variable windows_agents_configuration.count > 0

resource "azurerm_network_profile" "windows_network_profile" {
  count               = var.enable_vnet_integration ? var.windows_agents_configuration.count : 0
  name                = "windowsnetprofile${count.index}"
  location            = var.location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  container_network_interface {
    name = "windowsnic${count.index}"

    ip_configuration {
      name      = "windowsip${count.index}"
      subnet_id = data.azurerm_subnet.subnet[0].id
    }
  }
}

resource "azurerm_container_group" "windows-container-group" {
  count               = var.windows_agents_configuration.count
  name                = "${var.windows_agents_configuration.agent_name_prefix}-${count.index}"
  location            = var.location
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  ip_address_type     = var.enable_vnet_integration ? "private" : "public"
  os_type             = "windows"
  network_profile_id  = var.enable_vnet_integration ? azurerm_network_profile.windows_network_profile[count.index].id : null

  container {
    name   = "${var.windows_agents_configuration.agent_name_prefix}-${count.index}"
    image  = "${var.windows_agents_configuration.docker_image}:${var.windows_agents_configuration.docker_tag}"
    cpu    = var.windows_agents_configuration.cpu
    memory = var.windows_agents_configuration.memory

    # this field seems to be mandatory (error happens if not there). See https://github.com/terraform-providers/terraform-provider-azurerm/issues/1697#issuecomment-608669422
    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      AZP_URL        = "https://dev.azure.com/${var.azure_devops_org_name}"
      AZP_POOL       = var.windows_agents_configuration.agent_pool_name
      AZP_AGENT_NAME = "${var.windows_agents_configuration.agent_name_prefix}-${count.index}"
    }
    secure_environment_variables = {
      AZP_TOKEN = var.azure_devops_personal_access_token
    }
  }

  # if an image registry server has been specified, then generate the image_registry_credential block.
  dynamic "image_registry_credential" {
    for_each = var.image_registry_credential.server == "" ? [] : [1]
    content {
      username = var.image_registry_credential.username
      password = var.image_registry_credential.password
      server   = var.image_registry_credential.server
    }
  }
}
