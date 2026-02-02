# RBAC (Role-Based Access Control) Configuration for Azure Container Registry

# Data source for built-in Azure RBAC role definitions
data "azurerm_role_definition" "acr_pull" {
  name = "AcrPull"
}

data "azurerm_role_definition" "acr_push" {
  name = "AcrPush"
}

data "azurerm_role_definition" "acr_delete" {
  name = "AcrDelete"
}

data "azurerm_role_definition" "owner" {
  name = "Owner"
}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

# Role Assignments - Dynamically created based on var.role_assignments
resource "azurerm_role_assignment" "acr_role_assignments" {
  for_each = var.role_assignments

  scope                = azurerm_container_registry.acr.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id

  skip_service_principal_aad_check = true
}

# Output role assignment information
output "role_assignments_info" {
  description = "Information about created role assignments"
  value = {
    for k, v in azurerm_role_assignment.acr_role_assignments : k => {
      role         = v.role_definition_name
      principal_id = v.principal_id
      scope        = v.scope
    }
  }
  sensitive = false
}
