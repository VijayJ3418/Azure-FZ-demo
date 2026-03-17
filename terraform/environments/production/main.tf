terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }

  # Uncomment for Terraform Cloud integration
  # cloud {
  #   organization = "your-org-name"
  #   workspaces {
  #     name = "firezone-azure-prod"
  #   }
  # }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateprodaccount"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = false
}

# Create resource groups
resource "azurerm_resource_group" "networking" {
  name     = "rg-${var.project_name}-networking-${var.environment}"
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "jenkins" {
  name     = "rg-${var.project_name}-jenkins-${var.environment}"
  location = var.azure_region
  tags     = local.common_tags
}

resource "azurerm_resource_group" "firezone" {
  name     = "rg-${var.project_name}-firezone-${var.environment}"
  location = var.azure_region
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_name     = var.project_name
  environment      = var.environment
  azure_region     = var.azure_region
  resource_group_1 = azurerm_resource_group.networking.name
  resource_group_2 = azurerm_resource_group.jenkins.name

  vnet1_name                   = var.vnet1_name
  vnet1_cidr                   = var.vnet1_cidr
  vnet1_gateway_subnet_cidr    = var.vnet1_gateway_subnet_cidr
  vnet1_management_subnet_cidr = var.vnet1_management_subnet_cidr

  vnet2_name              = var.vnet2_name
  vnet2_cidr              = var.vnet2_cidr
  vnet2_jenkins_subnet_cidr = var.vnet2_jenkins_subnet_cidr

  tags = local.common_tags

  depends_on = [azurerm_resource_group.networking, azurerm_resource_group.jenkins]
}

# Jenkins Module
module "jenkins_stack" {
  source = "../../modules/jenkins"

  project_name    = var.project_name
  environment     = var.environment
  azure_region    = var.azure_region
  resource_group  = azurerm_resource_group.jenkins.name
  
  subnet_id                = module.networking.vnet2_jenkins_subnet_id
  vm_private_ip            = var.jenkins_vm_private_ip
  
  admin_username           = var.jenkins_admin_username
  ssh_public_key_path      = var.ssh_public_key_path
  ssh_public_key_content   = var.ssh_public_key_content
  
  os_disk_size_gb          = var.jenkins_os_disk_size_gb
  data_disk_size_gb        = var.jenkins_data_disk_size_gb
  
  vm_size                  = var.jenkins_vm_size
  
  certificate_path         = var.certificate_path
  certificate_content      = var.certificate_content
  certificate_key_path     = var.certificate_key_path
  certificate_key_content  = var.certificate_key_content
  
  dns_zone_id              = azurerm_private_dns_zone.dglearn.id
  dns_zone_name            = azurerm_private_dns_zone.dglearn.name

  tags = local.common_tags

  depends_on = [module.networking]
}

# Firezone Module
module "firezone_gateway" {
  source = "../../modules/firezone"

  project_name           = var.project_name
  environment            = var.environment
  azure_region           = var.azure_region
  resource_group         = azurerm_resource_group.firezone.name
  
  subnet_id              = module.networking.vnet1_gateway_subnet_id
  vm_private_ip          = var.firezone_gateway_private_ip
  
  admin_username         = var.firezone_admin_username
  ssh_public_key_path    = var.ssh_public_key_path
  ssh_public_key_content = var.ssh_public_key_content
  
  firezone_api_url       = var.firezone_api_url
  firezone_enrollment_token = var.firezone_enrollment_token
  
  vm_size                = var.firezone_vm_size

  tags = local.common_tags

  depends_on = [module.networking]
}

# Private DNS Zone for Jenkins
resource "azurerm_private_dns_zone" "dglearn" {
  name                = "dglearn.online"
  resource_group_name = azurerm_resource_group.jenkins.name

  tags = local.common_tags
}

# Link Private DNS Zone to VNets
resource "azurerm_private_dns_zone_virtual_network_link" "dglearn_to_vnet1" {
  name                  = "link-vnet1-dglearn"
  resource_group_name   = azurerm_resource_group.jenkins.name
  private_dns_zone_name = azurerm_private_dns_zone.dglearn.name
  virtual_network_id    = module.networking.vnet1_id
  registration_enabled  = false

  tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dglearn_to_vnet2" {
  name                  = "link-vnet2-dglearn"
  resource_group_name   = azurerm_resource_group.jenkins.name
  private_dns_zone_name = azurerm_private_dns_zone.dglearn.name
  virtual_network_id    = module.networking.vnet2_id
  registration_enabled  = false

  tags = local.common_tags
}

# A Record for Jenkins ILB
resource "azurerm_private_dns_a_record" "jenkins" {
  name                = "jenkins-azure"
  zone_name           = azurerm_private_dns_zone.dglearn.name
  resource_group_name = azurerm_resource_group.jenkins.name
  ttl                 = 300
  records             = [module.jenkins_stack.ilb_private_ip]

  tags = local.common_tags
}

# Local variables
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}
