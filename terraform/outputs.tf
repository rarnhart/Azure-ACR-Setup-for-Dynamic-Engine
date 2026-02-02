# Output values for Azure Container Registry

output "acr_id" {
  description = "The ID of the Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "The name of the Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The URL that can be used to log into the container registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The Username associated with the Container Registry Admin account (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_username : null
  sensitive   = false
}

output "acr_admin_password" {
  description = "The Password associated with the Container Registry Admin account (if enabled)"
  value       = var.admin_enabled ? azurerm_container_registry.acr.admin_password : null
  sensitive   = true
}

output "acr_sku" {
  description = "The SKU tier of the Container Registry"
  value       = azurerm_container_registry.acr.sku
}

output "acr_resource_group_name" {
  description = "The name of the resource group where ACR is located"
  value       = azurerm_container_registry.acr.resource_group_name
}

output "acr_location" {
  description = "The Azure region where the ACR is deployed"
  value       = azurerm_container_registry.acr.location
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = local.resource_group_id
}

# Connection strings and commands for convenience
output "docker_login_command" {
  description = "Command to log into the ACR using Azure CLI"
  value       = "az acr login --name ${azurerm_container_registry.acr.name}"
}

output "image_push_example" {
  description = "Example command to push an image to this registry"
  value       = "docker push ${azurerm_container_registry.acr.login_server}/myimage:latest"
}

output "image_pull_example" {
  description = "Example command to pull an image from this registry"
  value       = "docker pull ${azurerm_container_registry.acr.login_server}/myimage:latest"
}

# Configuration summary
output "configuration_summary" {
  description = "Complete configuration summary of the deployed ACR"
  value = {
    registry_name             = azurerm_container_registry.acr.name
    login_server              = azurerm_container_registry.acr.login_server
    resource_group            = azurerm_container_registry.acr.resource_group_name
    location                  = azurerm_container_registry.acr.location
    sku                       = azurerm_container_registry.acr.sku
    admin_enabled             = var.admin_enabled
    public_network_access     = var.public_network_access_enabled
    zone_redundancy           = var.sku == "Premium" ? var.enable_zone_redundancy : false
    retention_policy_enabled  = var.sku == "Premium" ? var.enable_retention_policy : false
    retention_days            = var.sku == "Premium" && var.enable_retention_policy ? var.retention_days : 0
    quarantine_policy_enabled = var.sku == "Premium" ? var.enable_quarantine_policy : false
    trust_policy_enabled      = var.sku == "Premium" ? var.enable_trust_policy : false
    diagnostics_enabled       = var.enable_diagnostics
  }
}

# Cost estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (excluding storage and data transfer)"
  value = var.sku == "Basic" ? "~$5/month" : (
    var.sku == "Standard" ? "~$20/month" : "~$50/month"
  )
}
