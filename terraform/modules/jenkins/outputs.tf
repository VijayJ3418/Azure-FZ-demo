# Jenkins Module - Outputs

output "vm_id" {
  description = "Jenkins VM resource ID"
  value       = azurerm_linux_virtual_machine.jenkins.id
}

output "vm_private_ip" {
  description = "Private IP address of Jenkins VM"
  value       = azurerm_linux_virtual_machine.jenkins.private_ip_addresses[0]
}

output "nsg_id" {
  description = "Network Security Group ID"
  value       = azurerm_network_security_group.jenkins.id
}

output "ilb_id" {
  description = "Internal Load Balancer ID"
  value       = azurerm_lb.jenkins_ilb.id
}

output "ilb_private_ip" {
  description = "Private IP address of Internal Load Balancer"
  value       = azurerm_lb.jenkins_ilb.private_ip_addresses[0]
}

output "backend_address_pool_id" {
  description = "Backend address pool ID"
  value       = azurerm_lb_backend_address_pool.jenkins.id
}

output "key_vault_id" {
  description = "Key Vault ID storing Jenkins certificates"
  value       = azurerm_key_vault.jenkins_certs.id
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.jenkins_certs.vault_uri
}

output "certificate_id" {
  description = "Certificate ID in Key Vault"
  value       = var.certificate_content != "" ? azurerm_key_vault_certificate.jenkins[0].id : null
}

output "data_disk_id" {
  description = "Data disk ID for /var/lib/jenkins"
  value       = azurerm_managed_disk.jenkins_data.id
}

output "network_interface_id" {
  description = "Network interface ID for Jenkins VM"
  value       = azurerm_network_interface.jenkins.id
}
