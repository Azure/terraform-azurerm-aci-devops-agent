# # Azure DevOps Agents ACI Terraform module - Deploy Linux agents in an existing virtual network

This directory contains Terraform configuration to deploy Azure DevOps agents in Linux containers on ACI, in an existing virtual network.

main.tf contains the creation of the virtual network and simple call to the module:

```hcl
resource "azurerm_resource_group" "vnet-rg" {
  name     = "rg-aci-devops-network"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aci-devops"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vnet-rg.location
  resource_group_name = azurerm_resource_group.vnet-rg.name
}

resource "azurerm_subnet" "aci-subnet" {
  name                 = "aci-subnet"
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
  source                   = "../../"
  enable_vnet_integration  = true
  vnet_resource_group_name = azurerm_resource_group.vnet-rg.name
  vnet_name                = azurerm_virtual_network.vnet.name
  subnet_name              = azurerm_subnet.aci-subnet.name
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
```

You can check the [main README](../../README.md#build-the-docker-images) to understand how to build your own Docker images.

## How to use it

Before running this sample, you need to [create an agent pool in your Azure DevOps organization](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser#creating-agent-pools) and a [personal access token](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#permissions) that it authorized to manage this agent pool.

This configuration has 3 variables:

- `azure_devops_org_name`: the name of your Azure DevOps organization (if you are connecting to `https://dev.azure.com/helloworld`, then helloworld is your organization name)
- `azure_devops_pool_name`: the name of the agent pool that you have created
- `azure_devops_personal_access_token`: the personal access token that you have generated

Then, you can just Terraform it:

```bash
terraform init
terraform plan \
    -var azure_devops_org_name="your_org_name" \
    -var azure_devops_pool_name="your_pool_name" \
    -var azure_devops_personal_access_token="pat_token" \
    -out aci-linux-devops-agents.plan

terraform apply "aci-linux-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy \
    -var azure_devops_org_name="your_org_name" \
    -var azure_devops_pool_name="your_pool_name" \
    -var azure_devops_personal_access_token="pat_token"
```
