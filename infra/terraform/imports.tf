# Resources created manually with the Azure CLI on 2026-11-08, adopted into Terraform.
# After the first successful apply these blocks are no-ops; kept as a record.

import {
  to = azurerm_resource_group.main
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
}

import {
  to = azurerm_container_registry.main
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
}
