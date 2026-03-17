output "resource_group_networking" {
  description = "Networking resource group name"
  value       = azurerm_resource_group.networking.name
}

output "resource_group_jenkins" {
  description = "Jenkins resource group name"
  value       = azurerm_resource_group.jenkins.name
}

output "resource_group_firezone" {
  description = "Firezone resource group name"
  value       = azurerm_resource_group.firezone.name
}

# VNet Outputs
output "vnet1_id" {
  description = "ID of Transit Hub VNet (Firezone Gateway)"
  value       = module.networking.vnet1_id
}

output "vnet1_name" {
  description = "Name of Transit Hub VNet"
  value       = module.networking.vnet1_name
}

output "vnet2_id" {
  description = "ID of Core IT Infrastructure VNet (Jenkins)"
  value       = module.networking.vnet2_id
}

output "vnet2_name" {
  description = "Name of Core IT Infrastructure VNet"
  value       = module.networking.vnet2_name
}

# Peering Outputs
output "peering_vnet1_to_vnet2" {
  description = "VNet Peering from VNet1 to VNet2"
  value       = module.networking.peering_vnet1_to_vnet2_id
}

output "peering_vnet2_to_vnet1" {
  description = "VNet Peering from VNet2 to VNet1"
  value       = module.networking.peering_vnet2_to_vnet1_id
}

# Jenkins Outputs
output "jenkins_vm_id" {
  description = "Jenkins VM resource ID"
  value       = module.jenkins_stack.vm_id
}

output "jenkins_vm_private_ip" {
  description = "Private IP address of Jenkins VM"
  value       = module.jenkins_stack.vm_private_ip
}

output "jenkins_ilb_private_ip" {
  description = "Private IP address of Jenkins Internal Load Balancer"
  value       = module.jenkins_stack.ilb_private_ip
}

output "jenkins_ilb_id" {
  description = "Jenkins Internal Load Balancer resource ID"
  value       = module.jenkins_stack.ilb_id
}

output "jenkins_dns_fqdn" {
  description = "Fully qualified domain name for Jenkins"
  value       = "jenkins-azure.${azurerm_private_dns_zone.dglearn.name}"
}

output "jenkins_nsg_id" {
  description = "Network Security Group ID for Jenkins"
  value       = module.jenkins_stack.nsg_id
}

# Firezone Outputs
output "firezone_gateway_vm_id" {
  description = "Firezone Gateway VM resource ID"
  value       = module.firezone_gateway.vm_id
}

output "firezone_gateway_private_ip" {
  description = "Private IP address of Firezone Gateway"
  value       = module.firezone_gateway.vm_private_ip
}

output "firezone_gateway_nsg_id" {
  description = "Network Security Group ID for Firezone Gateway"
  value       = module.firezone_gateway.nsg_id
}

# Private DNS Outputs
output "private_dns_zone_id" {
  description = "Private DNS Zone ID"
  value       = azurerm_private_dns_zone.dglearn.id
}

output "private_dns_zone_name" {
  description = "Private DNS Zone name"
  value       = azurerm_private_dns_zone.dglearn.name
}

output "jenkins_a_record_fqdn" {
  description = "FQDN of Jenkins A record in Private DNS"
  value       = "${azurerm_private_dns_a_record.jenkins.name}.${azurerm_private_dns_zone.dglearn.name}"
}

# Network Outputs
output "vnet1_gateway_subnet_id" {
  description = "Gateway Subnet ID in VNet1"
  value       = module.networking.vnet1_gateway_subnet_id
}

output "vnet1_management_subnet_id" {
  description = "Management Subnet ID in VNet1"
  value       = module.networking.vnet1_management_subnet_id
}

output "vnet2_jenkins_subnet_id" {
  description = "Jenkins Subnet ID in VNet2"
  value       = module.networking.vnet2_jenkins_subnet_id
}
