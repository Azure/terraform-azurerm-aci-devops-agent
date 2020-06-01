# Azure DevOps Agents ACI Terraform module - Deploy both Linux and Windows agents

This directory contains Terraform configuration to deploy Azure DevOps Linux and Windows agents in containers on ACI.

main.tf contains a simple call to the module:

```hcl
module "aci-devops-agent" {
  source                  = "../../"
  enable_vnet_integration = false
  linux_agents_configuration = {
    agent_name_prefix = "linux-agent"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-linux"
    agent_pool_name   = var.linux_azure_devops_pool_name
  }
  windows_agents_configuration = {
    agent_name_prefix = "windows-agent"
    count             = 2,
    docker_image      = "jcorioland/aci-devops-agent"
    docker_tag        = "0.2-win"
    agent_pool_name   = var.windows_azure_devops_pool_name
  }
  resource_group_name                = "rg-aci-devops-agents-we"
  location                           = "westeurope"
  azure_devops_org_name              = var.azure_devops_org_name
  azure_devops_personal_access_token = var.azure_devops_personal_access_token
}
```

You can check the [main README](../../README.md#build-the-docker-images) to understand how to build your own Docker images.

## How to use it

Before running this sample, you need to [create one or two agent pools in your Azure DevOps organization (one for Linux agents, and one for Windows agents)](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser#creating-agent-pools) and a [personal access token](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#permissions) that it authorized to manage this agent pool.

This configuration has 3 variables:

- `azure_devops_org_name`: the name of your Azure DevOps organization (if you are connecting to `https://dev.azure.com/helloworld`, then helloworld is your organization name)
- `linux_azure_devops_pool_name`: the name of the agent pool that you have created for the Linux agents
- `windows_azure_devops_pool_name`: the name of the agent pool that you have created for the Windows agents
- `azure_devops_personal_access_token`: the personal access token that you have generated

Then, you can just Terraform it:

```bash
terraform init
terraform plan \
    -var azure_devops_org_name="your_org_name" \
    -var azure_devops_personal_access_token="pat_token" \
    -var linux_azure_devops_pool_name="your_pool_name" \
    -var windows_azure_devops_pool_name="your_pool_name" \
    -out aci-devops-agents.plan

terraform apply "aci-devops-agents.plan"
```

You can destroy everything using `terraform destroy`:

```bash
terraform destroy \
    -var azure_devops_org_name="your_org_name" \
    -var azure_devops_personal_access_token="pat_token" \
    -var linux_azure_devops_pool_name="your_pool_name" \
    -var windows_azure_devops_pool_name="your_pool_name" \
```
