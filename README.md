# terraform-azurerm-aci-devops-agent

This repository contains a Terraform module that helps you to deploy [Azure DevOps self-hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser#install) running on Azure Container Instance.

You can choose to deploy Linux or Windows agents, provide custom Docker images for the agents to include the tools you really need. It also give you the option to deploy the agents into a private virtual network, if the agents needs to access internal resources.

## How-to use this module to deploy Azure DevOps agents

### Build the Docker images

This module requires that you build your own Linux and/or Windows Docker images, to run the Azure DevOps agents. The [docker](docker/README.md) contains Dockerfile and instructions for both.

### Create an Azure DevOps agent pool and personal access token

Before running this module, you need to [create an agent pool in your Azure DevOps organization](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser#creating-agent-pools) and a [personal access token](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#permissions) that it authorized to manage this agent pool.

This module has 3 variables related to Azure DevOps:

- `azure_devops_org_name`: the name of your Azure DevOps organization (if you are connecting to `https://dev.azure.com/helloworld`, then `helloworld` is your organization name)
- `azure_devops_personal_access_token`: the personal access token that you have generated
- `agent_pool_name`: both in the `linux_agents_configuration` and `windows_agents_configuration`, it is the name of the agent pool that you have created in which the Linux or Windows agents must be deployed

### Terraform ACI DevOps Agents usage

#### Create or use an existing a resource group

This module offers to create a new resource group to deploy the Azure Container instances into it, or import an existing one. This behavior is controlled using the `create_resource_group` flag:

- if `create_resource_group` is set to true, the module will create a resource group named `resource_group_name` in the `location` region
- if `create_resource_group` is set to false, the module will import a resource group data source with the name `resource_group_name`

#### Terraform ACI DevOps Agents - Deploy Linux Agents

The configuration below can be used to deploy Linux DevOps agents using Azure Container Instances.

```hcl
module "aci-devops-agent" {
  source                  = "Azure/aci-devops-agent/azurerm"
  resource_group_name     = "rg-linux-devops-agents"
  location                = "westeurope"
  enable_vnet_integration = false
  create_resource_group   = true

  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    agent_pool_name   = "DEVOPS_POOL_NAME"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    cpu               = 1
    memory            = 4
  }
  azure_devops_org_name              = "DEVOPS_ORG_NAME"
  azure_devops_personal_access_token = "DEVOPS_PERSONAL_ACCESS_TOKEN"
}
```

Then, you can just Terraform it:

```bash
terraform init
terraform plan -out aci-linux-devops-agents.plan
terraform apply "aci-linux-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy
```

#### Terraform ACI DevOps Agents - Deploy Linux agents in an existing virtual network
*Note: Virtual Network integration is only supported for Linux Containers in ACI. This part [does not apply to Windows Containers](https://docs.microsoft.com/en-us/azure/container-instances/container-instances-virtual-network-concepts#other-limitations).*
The configuration below can be used to deploy Azure DevOps agents in Linux containers, in an existing virtual network. Windows containers are not yet supported in a container group deployed to a Virtual Network.

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
  source                   = "Azure/aci-devops-agent/azurerm"
  resource_group_name      = "rg-linux-devops-agents"
  location                 = "westeurope"
  enable_vnet_integration  = true
  create_resource_group    = true
  vnet_resource_group_name = azurerm_resource_group.vnet-rg.name
  vnet_name                = azurerm_virtual_network.vnet.name
  subnet_name              = azurerm_subnet.aci-subnet.name

  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    agent_pool_name   = "DEVOPS_POOL_NAME"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    cpu               = 1
    memory            = 4
  }

  azure_devops_org_name              = "DEVOPS_ORG_NAME"
  azure_devops_personal_access_token = "DEVOPS_PERSONAL_ACCESS_TOKEN"
}
```

Then, you can just Terraform it:

```bash
terraform init
terraform plan -out aci-linux-devops-agents.plan
terraform apply "aci-linux-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy
```

#### Terraform ACI DevOps Agents - Deploy both Linux and Windows agents

The configuration below can be used to deploy Azure DevOps Linux and Windows agents in containers on ACI.

```hcl
module "aci-devops-agent" {
  source                  = "Azure/aci-devops-agent/azurerm"
  resource_group_name     = "rg-aci-devops-agents-we"
  location                = "westeurope"
  enable_vnet_integration = false
  create_resource_group   = true

  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    agent_pool_name   = "DEVOPS_POOL_NAME"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    cpu               = 1
    memory            = 4
  }

  windows_agents_configuration = {
    agent_name_prefix = "windows-agent"
    agent_pool_name   = "DEVOPS_POOL_NAME"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-win"
    cpu               = 1
    memory            = 4
  }

  azure_devops_org_name              = "DEVOPS_ORG_NAME"
  azure_devops_personal_access_token = "DEVOPS_PERSONAL_ACCESS_TOKEN"
}
```

Then, you can just Terraform it:

```bash
terraform init
terraform plan -out aci-devops-agents.plan
terraform apply "aci-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy
```

#### Terraform ACI DevOps Agents - Use a private Docker image registry

This module allows to download the Docker images to use for the agents from a private Docker images registry, like Azure Container Registry. It can be done like below:

```hcl
module "aci-devops-agent" {
  source                  = "Azure/aci-devops-agent/azurerm"
  resource_group_name     = "rg-linux-devops-agents"
  location                = "westeurope"
  enable_vnet_integration = false
  create_resource_group   = true

  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    agent_pool_name   = "DEVOPS_POOL_NAME"
    count             = 2,
    docker_image      = "jcorioland.azurecr.io/azure-devops/aci-devops-agent"
    docker_tag        = "0.2-linux"
    cpu               = 1
    memory            = 4
  }
  azure_devops_org_name              = "DEVOPS_ORG_NAME"
  azure_devops_personal_access_token = "DEVOPS_PERSONAL_ACCESS_TOKEN"

  image_registry_credential = {
    username = "DOCKER_PRIVATE_REGISTRY_USERNAME"
    password = "DOCKER_PRIVATE_REGISTRY_PASSWORD"
    server   = "jcorioland.azurecr.io"
  }
}
```

Then, you can just Terraform it:

```bash
terraform init
terraform plan -out aci-linux-devops-agents.plan
terraform apply "aci-linux-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy
```

## Test

### Configurations

- [Configure Terraform for Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure)

We provide 2 ways to build, run, and test the module on a local development machine.  [Native (Mac/Linux)](#native-maclinux) or [Docker](#docker).

### Native (Mac/Linux)

#### Prerequisites

- [Ruby **(~> 2.3)**](https://www.ruby-lang.org/en/downloads/)
- [Bundler **(~> 1.15)**](https://bundler.io/)
- [Terraform **(~> 0.11.7)**](https://www.terraform.io/downloads.html)
- [Golang **(~> 1.12.3)**](https://golang.org/dl/)

#### Environment setup

We provide simple script to quickly set up module development environment:

```sh
$ curl -sSL https://raw.githubusercontent.com/Azure/terramodtest/master/tool/env_setup.sh | sudo bash
```

#### Run test

Then simply run it in local shell:

```sh
$ bundle install
$ rake build
$ rake full
```

### Docker

We provide a Dockerfile to build a new image based `FROM` the `microsoft/terraform-test` Docker hub image which adds additional tools / packages specific for this module (see Custom Image section).  Alternatively use only the `microsoft/terraform-test` Docker hub image [by using these instructions](https://github.com/Azure/terraform-test).

#### Prerequisites

- [Docker](https://www.docker.com/community-edition#/download)

#### Custom Image

This builds the custom image:

```sh
$ docker build --build-arg BUILD_ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID --build-arg BUILD_ARM_CLIENT_ID=$ARM_CLIENT_ID --build-arg BUILD_ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET --build-arg BUILD_ARM_TENANT_ID=$ARM_TENANT_ID -t azure-devops-agent-aci-test .
```

This runs the build and unit tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake build"
```

This runs the end to end tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake e2e"
```

This runs the full tests:

```sh
$ docker run --rm \
    -e TF_VAR_azure_devops_org_name=$AZDO_ORG_NAME \
    -e TF_VAR_azure_devops_personal_access_token=$AZDO_PAT \
    -e TF_VAR_azure_devops_pool_name=$AZDO_POOL_NAME \
    azure-devops-agent-aci-test /bin/bash -c "bundle install && rake full"
```

With:

- `AZDO_ORG_NAME` being the name of the Azure DevOps organization
- `AZDO_PAT` being the personal access token to connect to Azure DevOps
- `AZDO_POOL_NAME` being the name of the Azure DevOps agent pool

## Authors

Originally created by [Julien Corioland](http://github.com/jcorioland)

## License

[MIT](LICENSE)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
