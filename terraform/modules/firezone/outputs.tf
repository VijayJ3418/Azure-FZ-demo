# Firezone Module - Outputs

output "vm_id" {
  description = "Firezone Gateway VM resource ID"
  value       = azurerm_linux_virtual_machine.firezone.id
}

output "vm_private_ip" {
  description = "Private IP address of Firezone Gateway VM"
  value       = azurerm_linux_virtual_machine.firezone.private_ip_addresses[0]
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.firezone.id
}

output "network_interface_id" {
  description = "Network Interface ID"
  value       = azurerm_network_interface.firezone.id
}

output "storage_account_id" {
  description = "Storage Account ID for logs"
  value       = azurerm_storage_account.firezone_logs.id
}

output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.firezone_logs.name
}

output "logs_container_id" {
  description = "Storage container ID for gateway logs"
  value       = azurerm_storage_container.firezone_logs.id
}
