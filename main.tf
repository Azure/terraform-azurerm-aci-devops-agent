resource "azurerm_resource_group" "rg" {
  # the resource group is created only if the flag create_new_resource_group is set to true
  count    = var.create_new_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_resource_group" "rg" {
  # the resource group is imported only if the flag create_new_resource_group is set to false
  count = var.create_new_resource_group ? 0 : 1
  name  = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  # the subnet is imported only enable_vnet_integration is true
  count                = var.enable_vnet_integration ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_resource_group_name
}

# Linux Agents - deployed only if variable linux_agents_configuration.count > 0

resource "azurerm_network_profile" "linux_network_profile" {
  count               = var.enable_vnet_integration ? var.linux_agents_configuration.count : 0
  name                = "linuxnetprofile${count.index}"
  location            = var.location
  resource_group_name = var.create_new_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

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
  resource_group_name = var.create_new_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
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
      AZP_TOKEN      = var.azure_devops_personal_access_token
      AZP_AGENT_NAME = "${var.linux_agents_configuration.agent_name_prefix}-${count.index}"
    }
  }
}

# Windows Agents - deployed only if variable windows_agents_configuration.count > 0

resource "azurerm_network_profile" "windows_network_profile" {
  count               = var.enable_vnet_integration ? var.windows_agents_configuration.count : 0
  name                = "windowsnetprofile${count.index}"
  location            = var.location
  resource_group_name = var.create_new_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

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
  resource_group_name = var.create_new_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
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
      AZP_TOKEN      = var.azure_devops_personal_access_token
      AZP_AGENT_NAME = "${var.windows_agents_configuration.agent_name_prefix}-${count.index}"
    }
  }
}