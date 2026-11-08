# ---------- Network ----------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-polaris"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.10.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "jenkins" {
  name                 = "snet-jenkins"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "jenkins" {
  name                = "nsg-polaris-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # The only inbound rule. Jenkins UI (8080) is reached through an SSH tunnel, never exposed.
  security_rule {
    name                       = "allow-ssh-admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "jenkins" {
  subnet_id                 = azurerm_subnet.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

resource "azurerm_public_ip" "jenkins" {
  name                = "pip-polaris-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "jenkins" {
  name                = "nic-polaris-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.jenkins.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }
}

# ---------- VM ----------
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                            = var.vm_name
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.jenkins.id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file("${path.module}/../ssh/polaris-jenkins.pub")
  }

  os_disk {
    name                 = "osdisk-polaris-jenkins"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Managed boot diagnostics: enables the serial console for break-glass access
  boot_diagnostics {}

  lifecycle {
    # SSH keys are rotated with `az vm user update` (runbook), not by replacing the VM
    ignore_changes = [admin_ssh_key]
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "jenkins" {
  virtual_machine_id    = azurerm_linux_virtual_machine.jenkins.id
  location              = azurerm_resource_group.main.location
  enabled               = true
  daily_recurrence_time = "2300"
  timezone              = "India Standard Time"
  tags                  = var.tags

  notification_settings {
    enabled = false
  }
}

# ---------- Least-privilege access for Jenkins (managed identity, no secrets) ----------
resource "azurerm_role_assignment" "jenkins_acr_push" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPush"
  principal_id                     = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "jenkins_aks_user" {
  scope                            = azurerm_kubernetes_cluster.main.id
  role_definition_name             = "Azure Kubernetes Service Cluster User Role"
  principal_id                     = azurerm_linux_virtual_machine.jenkins.identity[0].principal_id
  skip_service_principal_aad_check = true
}
