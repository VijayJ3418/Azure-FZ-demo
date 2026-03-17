# Jenkins Module - Variables

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "azure_region" {
  description = "Azure region"
  type        = string
}

variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where Jenkins will be deployed"
  type        = string
}

variable "vm_private_ip" {
  description = "Private IP address for Jenkins VM"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 50
}

variable "data_disk_size_gb" {
  description = "Size of data disk in GB for /var/lib/jenkins"
  type        = number
  default     = 100
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "certificate_path" {
  description = "Path to SSL certificate file (PEM format with full chain)"
  type        = string
}

variable "certificate_key_path" {
  description = "Path to SSL certificate private key"
  type        = string
}

variable "dns_zone_id" {
  description = "Private DNS Zone ID"
  type        = string
}

variable "dns_zone_name" {
  description = "Private DNS Zone name"
  type        = string
}

variable "ilb_private_ip" {
  description = "Private IP address for Internal Load Balancer"
  type        = string
  default     = "30.30.30.100"
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
