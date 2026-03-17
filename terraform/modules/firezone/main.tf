# Firezone Module - Main Configuration

# Network Interface for Firezone Gateway VM
resource "azurerm_network_interface" "firezone" {
  name                = "nic-${var.project_name}-firezone-gateway"
  location            = var.azure_region
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip
  }

  tags = var.tags
}

# Network Security Group for Firezone
resource "azurerm_network_security_group" "firezone" {
  name                = "${var.project_name}-firezone-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group

  # SSH Access
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

  # WireGuard VPN (for clients)
  security_rule {
    name                       = "AllowWireGuardUDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "51820"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # API/Control plane communication
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow egress to Jenkins
  security_rule {
    name                       = "AllowOutToJenkins"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.jenkins_vnet_cidr
  }

  # Allow outbound to internet (for API calls)
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

# Associate NSG with Firezone NIC
resource "azurerm_network_interface_security_group_association" "firezone" {
  network_interface_id      = azurerm_network_interface.firezone.id
  network_security_group_id = azurerm_network_security_group.firezone.id
}

# Firezone Gateway VM (Rocky Linux)
resource "azurerm_linux_virtual_machine" "firezone" {
  name                = "vm-${var.project_name}-firezone-gateway"
  location            = var.azure_region
  resource_group_name = var.resource_group
  size                = var.vm_size

  admin_username = var.admin_username

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key_content != "" ? var.ssh_public_key_content : try(file(var.ssh_public_key_path), "ERROR: SSH public key not provided. Set ssh_public_key_content variable.")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "RockyLinux-x86"
    sku       = "rocky-8-LVM"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.firezone.id,
  ]

  # User data script to install and configure Firezone Gateway
  custom_data = base64encode(templatefile("${path.module}/scripts/firezone-init.sh", {
    firezone_api_url          = var.firezone_api_url
    firezone_enrollment_token = var.firezone_enrollment_token
  }))

  tags = var.tags

  depends_on = [azurerm_network_interface.firezone]
}

# Storage Account for VPN logging (optional)
resource "azurerm_storage_account" "firezone_logs" {
  name                     = "st${replace(var.project_name, "-", "")}fz${var.environment}"
  resource_group_name      = var.resource_group
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# Storage container for gateway logs
resource "azurerm_storage_container" "firezone_logs" {
  name                  = "firezone-gateway-logs"
  storage_account_name  = azurerm_storage_account.firezone_logs.name
  container_access_type = "private"
}
