# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group - Create new or reference existing
resource "azurerm_resource_group" "acr_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "existing_rg" {
  count = var.create_resource_group ? 0 : 1
  name  = var.resource_group_name
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.acr_rg[0].name : data.azurerm_resource_group.existing_rg[0].name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.acr_rg[0].id : data.azurerm_resource_group.existing_rg[0].id
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.registry_name
  resource_group_name = local.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Public network access
  public_network_access_enabled = var.public_network_access_enabled

  # Zone redundancy (Premium only)
  zone_redundancy_enabled = var.sku == "Premium" ? var.enable_zone_redundancy : false

  # Export policy
  export_policy_enabled = var.enable_export_policy

  # Quarantine policy (Premium only)
  quarantine_policy_enabled = var.sku == "Premium" ? var.enable_quarantine_policy : false

  # Retention policy (Premium only)
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" && var.enable_retention_policy ? [1] : []
    content {
      days    = var.retention_days
      enabled = true
    }
  }

  # Trust policy (Premium only)
  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.enable_trust_policy ? [1] : []
    content {
      enabled = true
    }
  }

  # Network rule set for IP filtering
  dynamic "network_rule_set" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.allowed_ip_ranges
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.registry_name
      SKU  = var.sku
    }
  )

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Diagnostic Settings (if enabled)
resource "azurerm_monitor_diagnostic_setting" "acr_diagnostics" {
  count                      = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "${var.registry_name}-diagnostics"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Output registry creation info
output "registry_creation_info" {
  description = "ACR creation information"
  value = {
    name             = azurerm_container_registry.acr.name
    resource_group   = azurerm_container_registry.acr.resource_group_name
    location         = azurerm_container_registry.acr.location
    sku              = azurerm_container_registry.acr.sku
    admin_enabled    = azurerm_container_registry.acr.admin_enabled
    public_access    = var.public_network_access_enabled
    zone_redundancy  = var.sku == "Premium" ? var.enable_zone_redundancy : false
    retention_policy = var.sku == "Premium" && var.enable_retention_policy ? "${var.retention_days} days" : "disabled"
  }
}
