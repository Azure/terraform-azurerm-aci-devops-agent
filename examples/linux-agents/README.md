# Azure DevOps Agents ACI Terraform module - Deploy Linux Agents

This directory contains Terraform configuration to deploy Azure DevOps Linux agents in containers on ACI.

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
  }
  resource_group_name = "rg-linux-devops-agents"
  location            = "westeurope"
  azure_devops_org_name = var.azure_devops_org_name
  azure_devops_pool_name = var.azure_devops_pool_name
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
