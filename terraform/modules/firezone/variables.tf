# Firezone Module - Variables

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
  description = "Subnet ID where Firezone Gateway will be deployed"
  type        = string
}

variable "vm_private_ip" {
  description = "Private IP address for Firezone Gateway VM"
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
  default     = ""  # Optional - can be omitted if using ssh_public_key_content
}

variable "ssh_public_key_content" {
  description = "SSH public key content (alternative to ssh_public_key_path for cloud deployment)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "vm_size" {
  description = "VM size for Firezone Gateway"
  type        = string
  default     = "Standard_B2s"
}

variable "firezone_api_url" {
  description = "Firezone API URL (Control Plane endpoint)"
  type        = string
}

variable "firezone_enrollment_token" {
  description = "Firezone Gateway enrollment token from Firezone Console"
  type        = string
  sensitive   = true
}

variable "jenkins_vnet_cidr" {
  description = "CIDR block of Jenkins VNet for egress rules"
  type        = string
  default     = "30.30.30.0/16"
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
