output "resource_group_name" {
    value       = azurerm_resource_group.rg.name
    description = "resource group where linux container agent are deployed"
}
output "linux_container_group_name" {
  value       = module.aci-devops-agent.linux_agents_names[0]
  description = "name of the first Linux container group"
}
