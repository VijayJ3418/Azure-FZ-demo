# Networking Module - Main Configuration

resource "azurerm_virtual_network" "vnet1" {
  name                = var.vnet1_name
  address_space       = [var.vnet1_cidr]
  location            = var.azure_region
  resource_group_name = var.resource_group_1

  tags = var.tags
}

resource "azurerm_subnet" "vnet1_gateway" {
  name                 = "${var.vnet1_name}-gateway-subnet"
  resource_group_name  = var.resource_group_1
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.vnet1_gateway_subnet_cidr]
}

resource "azurerm_subnet" "vnet1_management" {
  name                 = "${var.vnet1_name}-management-subnet"
  resource_group_name  = var.resource_group_1
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = [var.vnet1_management_subnet_cidr]
}

# Core IT Infrastructure VNet
resource "azurerm_virtual_network" "vnet2" {
  name                = var.vnet2_name
  address_space       = [var.vnet2_cidr]
  location            = var.azure_region
  resource_group_name = var.resource_group_2

  tags = var.tags
}

resource "azurerm_subnet" "vnet2_jenkins" {
  name                 = "${var.vnet2_name}-jenkins-subnet"
  resource_group_name  = var.resource_group_2
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.vnet2_jenkins_subnet_cidr]
}

# VNet Peering Configuration
resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "${var.vnet1_name}-to-${var.vnet2_name}"
  resource_group_name       = var.resource_group_1
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "${var.vnet2_name}-to-${var.vnet1_name}"
  resource_group_name       = var.resource_group_2
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Network Security Groups for VNet1 (Firezone Gateway)
resource "azurerm_network_security_group" "vnet1_gateway_nsg" {
  name                = "${var.vnet1_name}-gateway-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group_1

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowFirezoneWireGuard"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "51820"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutToJenkins"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.vnet2_cidr
  }

  security_rule {
    name                       = "AllowOutToInternet"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "vnet1_gateway" {
  subnet_id                 = azurerm_subnet.vnet1_gateway.id
  network_security_group_id = azurerm_network_security_group.vnet1_gateway_nsg.id
}

# Network Security Groups for VNet2 (Jenkins)
resource "azurerm_network_security_group" "vnet2_jenkins_nsg" {
  name                = "${var.vnet2_name}-jenkins-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group_2

  security_rule {
    name                       = "AllowSSHFromVNet1"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.vnet1_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowJenkinsHTTPSFromVNet1"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.vnet1_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowILBInterval"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowOutToInternet"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "vnet2_jenkins" {
  subnet_id                 = azurerm_subnet.vnet2_jenkins.id
  network_security_group_id = azurerm_network_security_group.vnet2_jenkins_nsg.id
}

# Route Tables to facilitate inter-VPC traffic
resource "azurerm_route_table" "vnet1_routes" {
  name                = "${var.vnet1_name}-routes"
  location            = var.azure_region
  resource_group_name = var.resource_group_1

  route {
    name                   = "to-jenkins-vnet"
    address_prefix         = var.vnet2_cidr
    next_hop_type          = "VirtualNetworkPeering"
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "vnet1_gateway" {
  subnet_id      = azurerm_subnet.vnet1_gateway.id
  route_table_id = azurerm_route_table.vnet1_routes.id
}

resource "azurerm_route_table" "vnet2_routes" {
  name                = "${var.vnet2_name}-routes"
  location            = var.azure_region
  resource_group_name = var.resource_group_2

  route {
    name                   = "to-firezone-vnet"
    address_prefix         = var.vnet1_cidr
    next_hop_type          = "VirtualNetworkPeering"
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "vnet2_jenkins" {
  subnet_id      = azurerm_subnet.vnet2_jenkins.id
  route_table_id = azurerm_route_table.vnet2_routes.id
}
