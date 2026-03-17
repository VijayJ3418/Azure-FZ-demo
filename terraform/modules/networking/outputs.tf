# Networking Module - Outputs

output "vnet1_id" {
  description = "ID of VNet1 (Transit Hub)"
  value       = azurerm_virtual_network.vnet1.id
}

output "vnet1_name" {
  description = "Name of VNet1"
  value       = azurerm_virtual_network.vnet1.name
}

output "vnet2_id" {
  description = "ID of VNet2 (Jenkins)"
  value       = azurerm_virtual_network.vnet2.id
}

output "vnet2_name" {
  description = "Name of VNet2"
  value       = azurerm_virtual_network.vnet2.name
}

output "vnet1_gateway_subnet_id" {
  description = "ID of Gateway subnet in VNet1"
  value       = azurerm_subnet.vnet1_gateway.id
}

output "vnet1_management_subnet_id" {
  description = "ID of Management subnet in VNet1"
  value       = azurerm_subnet.vnet1_management.id
}

output "vnet2_jenkins_subnet_id" {
  description = "ID of Jenkins subnet in VNet2"
  value       = azurerm_subnet.vnet2_jenkins.id
}

output "peering_vnet1_to_vnet2_id" {
  description = "ID of peering from VNet1 to VNet2"
  value       = azurerm_virtual_network_peering.vnet1_to_vnet2.id
}

output "peering_vnet2_to_vnet1_id" {
  description = "ID of peering from VNet2 to VNet1"
  value       = azurerm_virtual_network_peering.vnet2_to_vnet1.id
}

output "vnet1_gateway_nsg_id" {
  description = "ID of NSG for VNet1 Gateway subnet"
  value       = azurerm_network_security_group.vnet1_gateway_nsg.id
}

output "vnet2_jenkins_nsg_id" {
  description = "ID of NSG for VNet2 Jenkins subnet"
  value       = azurerm_network_security_group.vnet2_jenkins_nsg.id
}
