variable "subscription_id" {
  description = "Azure subscription ID (set via TF_VAR_subscription_id in infra/env.sh)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources (see ADR 0001)"
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Resource group for the platform"
  type        = string
  default     = "rg-polaris-devops"
}

variable "acr_name" {
  description = "Azure Container Registry name (globally unique)"
  type        = string
  default     = "acrpolaris4827"
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    project = "polaris"
    env     = "lab"
  }
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-polaris"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes minor version; upgrades are a reviewed one-line change"
  type        = string
  default     = "1.36"
}

variable "aks_node_size" {
  description = "VM size for the single system node (see ADR 0001)"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "vm_name" {
  description = "Jenkins VM name"
  type        = string
  default     = "vm-polaris-jenkins"
}

variable "vm_size" {
  description = "Jenkins VM size (see ADR 0001)"
  type        = string
  default     = "Standard_B2als_v2"
}

variable "vm_admin_username" {
  description = "Admin user on the Jenkins VM (SSH key only)"
  type        = string
  default     = "azureuser"
}

variable "admin_source_cidr" {
  description = "Your public IP as /32, allowed to SSH to the Jenkins VM (set via TF_VAR_admin_source_cidr in infra/env.sh)"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_source_cidr, 0)) && endswith(var.admin_source_cidr, "/32")
    error_message = "admin_source_cidr must be one IP like 203.0.113.10/32. Run: source infra/env.sh"
  }
}
