terraform {
  backend "azurerm" {
    resource_group_name  = "rg-polaris-tfstate"
    storage_account_name = "stpolaristf4827"
    container_name       = "tfstate"
    key                  = "platform.tfstate"
    use_azuread_auth     = true
  }
}
