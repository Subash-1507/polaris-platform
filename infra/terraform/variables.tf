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
