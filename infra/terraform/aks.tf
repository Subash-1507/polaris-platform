resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.aks_name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  node_resource_group = "rg-polaris-aks-nodes"
  oidc_issuer_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.aks_node_size
    node_count                  = 1
    os_disk_size_gb             = 64
    max_pods                    = 60
    temporary_name_for_rotation = "systemtmp"
    tags                        = var.tags

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "10.244.0.0/16"
  }

  tags = var.tags
}

# Equivalent of `az aks create --attach-acr`: the nodes' kubelet identity may pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
