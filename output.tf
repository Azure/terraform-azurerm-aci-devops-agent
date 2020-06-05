output "has_linux_agents" {
  value       = length(azurerm_container_group.linux-container-group) > 0 ? true : false
  description = "A flag that indicates if Linux agents have been deployed with the current configuration."
}

output "linux_agents_count" {
  value       = length(azurerm_container_group.linux-container-group)
  description = "A number that indicates the number of Linux agents that have been deployed with the current configuration."
}

output "linux_agents_names" {
  value       = azurerm_container_group.linux-container-group.*.name
  description = "An array that contains the names of Linux agents that have been deployed with the current configuration."
}

output "vnet_integration_enabled" {
  value       = var.enable_vnet_integration
  description = "A flag that indicates if the vnet integration has been enabled with the current configuration."
}

output "subnet_id" {
  value       = var.enable_vnet_integration ? data.azurerm_subnet.subnet[0].id : ""
  description = "If the vnet integration is enabled, the id of the subnet in which the agents are deployed."
}

output "has_windows_agents" {
  value       = length(azurerm_container_group.windows-container-group) > 0 ? true : false
  description = "A flag that indicates if Windows agents have been deployed with the current configuration."
}

output "windows_agents_count" {
  value       = length(azurerm_container_group.windows-container-group)
  description = "A number that indicates the number of Windows agents that have been deployed with the current configuration."
}

output "windows_agents_names" {
  value       = azurerm_container_group.windows-container-group.*.name
  description = "An array that contains the names of Windows agents that have been deployed with the current configuration."
}