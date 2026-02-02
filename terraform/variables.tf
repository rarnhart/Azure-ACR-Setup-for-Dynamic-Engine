variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "registry_name" {
  description = "Name of the Azure Container Registry. Must be globally unique, alphanumeric only, 5-50 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.registry_name))
    error_message = "Registry name must be 5-50 alphanumeric characters only (no hyphens, underscores, or special characters)."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group where ACR will be created"
  type        = string
}

variable "location" {
  description = "Azure region where the ACR will be deployed (e.g., eastus, westus2, westeurope)"
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "The SKU tier of the Container Registry. Options: Basic, Standard, Premium"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the registry. Not recommended for production; use RBAC instead."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the container registry"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to assign to the ACR resource"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Purpose     = "ContainerRegistry"
  }
}

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

variable "enable_retention_policy" {
  description = "Enable retention policy for untagged manifests (Premium tier only)"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Number of days to retain untagged manifests (1-365, Premium tier only)"
  type        = number
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "enable_quarantine_policy" {
  description = "Enable quarantine policy for container images (Premium tier only)"
  type        = bool
  default     = false
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for the registry (Premium tier only, specific regions)"
  type        = bool
  default     = false
}

variable "enable_export_policy" {
  description = "Enable export policy to allow/deny export of artifacts"
  type        = bool
  default     = true
}

variable "role_assignments" {
  description = "Map of role assignments to create. Key is a friendly name, value contains principal_id and role."
  type = map(object({
    principal_id = string
    role         = string
  }))
  default = {}
}

variable "allowed_ip_ranges" {
  description = "List of IP address ranges allowed to access the registry (CIDR notation)"
  type        = list(string)
  default     = []
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for ACR"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic logs (required if enable_diagnostics is true)"
  type        = string
  default     = null
}

variable "enable_trust_policy" {
  description = "Enable content trust for signed images (Premium tier only)"
  type        = bool
  default     = false
}
