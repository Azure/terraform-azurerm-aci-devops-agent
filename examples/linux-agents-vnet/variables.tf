variable azure_devops_org_name {
  type        = string
  description = "The name of the Azure DevOps organization in which the containerized agents will be deployed (e.g. https://dev.azure.com/YOUR_ORGANIZATION_NAME, must exist)"
}

variable azure_devops_pool_name {
  type        = string
  description = "The name of the Azure DevOps agent pool in which the containerized agents will be deployed (must exist)"
}

variable azure_devops_personal_access_token {
  type        = string
  description = "The personal access token to use to connect to Azure DevOps (see https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-windows?view=azure-devops#permissions)"
}