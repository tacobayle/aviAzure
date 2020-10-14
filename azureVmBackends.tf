
resource "azurerm_network_interface" "nicBackend" {
  depends_on = [azurerm_network_security_rule.sgRule, azurerm_subnet.subnet]
  count = var.backend["count"]
  name = "nic-backend${count.index}"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.1.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    createdBy = "Terraform"
  }
}

data "template_file" "backend" {
  template = file(var.backend["userdata"])
}

resource "azurerm_virtual_machine" "backend" {
  count = var.backend["count"]
  depends_on = [azurerm_network_interface.nicBackend]
  name          = "backend-${count.index + 1 }"
  location                  = var.azure["rgLocation"]
  resource_group_name       = azurerm_resource_group.rg.name
  vm_size                   = var.backend["type"]
  network_interface_ids     = [ azurerm_network_interface.nicBackend[count.index].id ]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

# az vm image list --output table

  storage_image_reference {
    publisher = var.backend["publisher"]
    offer     = var.backend["offer"]
    sku       = var.backend["sku"]
    version   = "latest"
  }

  storage_os_disk {
    name              = "backend-${count.index + 1 }-ssd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }


  os_profile {
    computer_name   = "backend-${count.index + 1 }"
    admin_username = var.backend["username"]
    custom_data = data.template_file.backend.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.backend["username"]}/.ssh/authorized_keys"
      key_data = file(var.backend["key"])
    }
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "backend"
  }
}
