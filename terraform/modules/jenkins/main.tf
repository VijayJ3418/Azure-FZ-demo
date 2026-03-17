# Jenkins Module - Main Configuration

# Network Interface for Jenkins VM
resource "azurerm_network_interface" "jenkins" {
  name                = "nic-${var.project_name}-jenkins"
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

# Associate NSG with Jenkins NIC
resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

# Network Security Group for Jenkins VM
resource "azurerm_network_security_group" "jenkins" {
  name                = "${var.project_name}-jenkins-nsg"
  location            = var.azure_region
  resource_group_name = var.resource_group

  tags = var.tags
}

# Jenkins Rocky Linux VM (Private IP Only)
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "vm-${var.project_name}-jenkins"
  location            = var.azure_region
  resource_group_name = var.resource_group
  size                = var.vm_size

  admin_username = var.admin_username

  # Disable password authentication, use SSH keys only
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "RockyLinux-x86"
    sku       = "rocky-8-LVM"  # Use Rocky Linux 8
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.jenkins.id,
  ]

  # User data script to install and configure Jenkins
  custom_data = base64encode(templatefile("${path.module}/scripts/jenkins-init.sh", {
    certificate_path    = var.certificate_path
    certificate_key_path = var.certificate_key_path
  }))

  tags = var.tags

  depends_on = [azurerm_network_interface.jenkins]
}

# Managed Data Disk for Jenkins (/var/lib/jenkins)
resource "azurerm_managed_disk" "jenkins_data" {
  name                = "${var.project_name}-jenkins-data-disk"
  location            = var.azure_region
  resource_group_name = var.resource_group
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  tags = var.tags
}

# Attach data disk to Jenkins VM
resource "azurerm_virtual_machine_data_disk_attachment" "jenkins" {
  managed_disk_id    = azurerm_managed_disk.jenkins_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.jenkins.id
  lun                = 0
  caching            = "ReadWrite"
}

# Internal Load Balancer
resource "azurerm_lb" "jenkins_ilb" {
  name                = "ilb-${var.project_name}-jenkins"
  location            = var.azure_region
  resource_group_name = var.resource_group
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "ILBFrontend"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ilb_private_ip
  }

  tags = var.tags
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "jenkins" {
  name            = "backend-pool-jenkins"
  loadbalancer_id = azurerm_lb.jenkins_ilb.id
}

# Associate Jenkins NIC to Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "jenkins" {
  network_interface_id    = azurerm_network_interface.jenkins.id
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.jenkins.id
}

# HTTPS Probe
resource "azurerm_lb_probe" "jenkins_https" {
  loadbalancer_id     = azurerm_lb.jenkins_ilb.id
  name                = "https-probe"
  port                = 443
  protocol            = "Https"
  request_path        = "/"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# HTTPS Load Balancing Rule (both frontend and backend on 443)
resource "azurerm_lb_rule" "jenkins_https" {
  loadbalancer_id                = azurerm_lb.jenkins_ilb.id
  name                           = "HTTPS-Rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "ILBFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.jenkins.id]
  probe_id                       = azurerm_lb_probe.jenkins_https.id
  enable_tcp_reset               = true
}

# SSL/TLS Certificate - Uploaded to Azure Key Vault
resource "azurerm_key_vault" "jenkins_certs" {
  name                       = "kv-${replace(var.project_name, "-", "")}jenkins"
  location                   = var.azure_region
  resource_group_name        = var.resource_group
  enabled_for_disk_encryption = true
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Import",
      "Delete"
    ]
  }

  tags = var.tags
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Store certificate in Key Vault
resource "azurerm_key_vault_certificate" "jenkins" {
  name         = "${var.project_name}-jenkins-cert"
  key_vault_id = azurerm_key_vault.jenkins_certs.id

  certificate {
    contents = file(var.certificate_path)
  }

  depends_on = [azurerm_key_vault.jenkins_certs]
}
