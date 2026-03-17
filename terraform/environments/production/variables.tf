variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "firezone"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

# Networking Variables
variable "vnet1_name" {
  description = "Name of the Transit Hub VNet (Firezone Gateway)"
  type        = string
  default     = "Networking-Global"
}

variable "vnet1_cidr" {
  description = "CIDR block for VNet1 (Transit Hub)"
  type        = string
  default     = "10.10.10.0/16"
}

variable "vnet1_gateway_subnet_cidr" {
  description = "CIDR block for Firezone Gateway subnet"
  type        = string
  default     = "10.10.10.0/24"
}

variable "vnet1_management_subnet_cidr" {
  description = "CIDR block for Management subnet in VNet1"
  type        = string
  default     = "10.10.11.0/24"
}

variable "vnet2_name" {
  description = "Name of Core IT Infrastructure VNet (Jenkins)"
  type        = string
  default     = "Core-IT-Infrastructure"
}

variable "vnet2_cidr" {
  description = "CIDR block for VNet2 (Jenkins)"
  type        = string
  default     = "30.30.30.0/16"
}

variable "vnet2_jenkins_subnet_cidr" {
  description = "CIDR block for Jenkins subnet in VNet2"
  type        = string
  default     = "30.30.30.0/24"
}

# Jenkins Variables
variable "jenkins_vm_private_ip" {
  description = "Private IP address for Jenkins VM"
  type        = string
  default     = "30.30.30.10"
}

variable "jenkins_admin_username" {
  description = "Admin username for Jenkins VM"
  type        = string
  default     = "azureuser"
  sensitive   = true
}

variable "jenkins_os_disk_size_gb" {
  description = "Size of OS disk for Jenkins VM"
  type        = number
  default     = 50
}

variable "jenkins_data_disk_size_gb" {
  description = "Size of data disk for /var/lib/jenkins"
  type        = number
  default     = 100
}

variable "jenkins_vm_size" {
  description = "VM size for Jenkins"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "certificate_path" {
  description = "Path to SSL certificate file (full chain: Root + Intermediate + Leaf)"
  type        = string
  default     = ""
}

variable "certificate_content" {
  description = "SSL certificate content (PEM format) - use this for cloud deployments"
  type        = string
  sensitive   = true
  default     = ""
}

variable "certificate_key_path" {
  description = "Path to SSL certificate private key"
  type        = string
  default     = ""
}

variable "certificate_key_content" {
  description = "SSL certificate private key content - use this for cloud deployments"
  type        = string
  sensitive   = true
  default     = ""
}

# Firezone Variables
variable "firezone_gateway_private_ip" {
  description = "Private IP address for Firezone Gateway"
  type        = string
  default     = "10.10.10.10"
}

variable "firezone_admin_username" {
  description = "Admin username for Firezone Gateway VM"
  type        = string
  default     = "azureuser"
  sensitive   = true
}

variable "firezone_vm_size" {
  description = "VM size for Firezone Gateway"
  type        = string
  default     = "Standard_B2s"
}

variable "firezone_api_url" {
  description = "Firezone API URL (Control Plane)"
  type        = string
}

variable "firezone_enrollment_token" {
  description = "Firezone Gateway enrollment token"
  type        = string
  sensitive   = true
}

# SSH Key Variables
variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = ""
}

variable "ssh_public_key_content" {
  description = "SSH public key content - use this for cloud deployments instead of path"
  type        = string
  sensitive   = true
  default     = ""
}

# DNS Variables
variable "dns_zone_name" {
  description = "Private DNS zone name"
  type        = string
  default     = "dglearn.online"
}

variable "jenkins_dns_record" {
  description = "DNS record name for Jenkins"
  type        = string
  default     = "jenkins-azure"
}
