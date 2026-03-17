# Networking Module - Variables

variable "project_name" {
  description = "Project name for resource naming"
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

variable "resource_group_1" {
  description = "Resource group name for VNet1"
  type        = string
}

variable "resource_group_2" {
  description = "Resource group name for VNet2"
  type        = string
}

variable "vnet1_name" {
  description = "Name of the first VNet (Transit Hub)"
  type        = string
}

variable "vnet1_cidr" {
  description = "CIDR block for VNet1"
  type        = string
}

variable "vnet1_gateway_subnet_cidr" {
  description = "CIDR block for Gateway subnet in VNet1"
  type        = string
}

variable "vnet1_management_subnet_cidr" {
  description = "CIDR block for Management subnet in VNet1"
  type        = string
}

variable "vnet2_name" {
  description = "Name of the second VNet (Jenkins)"
  type        = string
}

variable "vnet2_cidr" {
  description = "CIDR block for VNet2"
  type        = string
}

variable "vnet2_jenkins_subnet_cidr" {
  description = "CIDR block for Jenkins subnet in VNet2"
  type        = string
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
