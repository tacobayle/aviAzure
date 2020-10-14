data "azurerm_subscription" "primary" {
}

resource "azurerm_public_ip" "controllerPublicIp" {
  name = "controllerPublicIp"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.azure["rgLocation"]
  allocation_method = "Static"
  sku                 = "Standard"
  tags = {
    createdBy = "Terraform"
  }
}

resource "azurerm_network_interface" "nicController" {
  depends_on = [azurerm_network_security_rule.sgRule, azurerm_subnet.subnet]
  name = "nic-controller"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.0.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controllerPublicIp.id
  }
  tags = {
    createdBy = "Terraform"
  }
}

resource "azurerm_virtual_machine" "controller" {
  name          = "controller"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
  vm_size                   = var.controller["type"]
  network_interface_ids     = [ azurerm_network_interface.nicController.id ]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "controller_ssd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      =  "128"
  }

  storage_image_reference {
    publisher = var.controller["publisher"]
    offer     = var.controller["offer"]
    sku       = var.controller["sku"]
    version   = var.controller["version"]
  }

  plan {
    name = var.controller["sku"]
    publisher = var.controller["publisher"]
    product = var.controller["offer"]
  }

  os_profile {
    computer_name = "controller"
    admin_username = "avi"
    admin_password = var.avi_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "controller"
  }
}

resource "azurerm_role_assignment" "avi_role_assignment" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id       = lookup(azurerm_virtual_machine.controller.identity[0], "principal_id")
}
