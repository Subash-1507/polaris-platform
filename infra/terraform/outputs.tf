output "resource_group_name" {
  description = "Platform resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "ACR login server used by Jenkins and AKS"
  value       = azurerm_container_registry.main.login_server
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_get_credentials" {
  description = "Command to fetch kubeconfig"
  value       = "az aks get-credentials -g ${azurerm_resource_group.main.name} -n ${azurerm_kubernetes_cluster.main.name} --overwrite-existing"
}
