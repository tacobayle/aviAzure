resource "azurerm_network_interface" "nicMysql" {
  depends_on = [azurerm_network_security_rule.sgRule, azurerm_subnet.subnet]
  name = "nic-mysql"
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

data "template_file" "mysql" {
  template = file(var.mysql["userdata"])
}

resource "azurerm_virtual_machine" "mysql" {
  depends_on = [azurerm_network_interface.nicMysql]
  name          = "mysql"
  location                  = var.azure["rgLocation"]
  resource_group_name       = azurerm_resource_group.rg.name
  vm_size                   = var.mysql["type"]
  network_interface_ids     = [ azurerm_network_interface.nicMysql.id ]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

# az vm image list --output table

  storage_image_reference {
    publisher = var.mysql["publisher"]
    offer     = var.mysql["offer"]
    sku       = var.mysql["sku"]
    version   = "latest"
  }

  storage_os_disk {
    name              = "mysql-ssd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }


  os_profile {
    computer_name   = "mysql"
    admin_username = var.mysql["username"]
    custom_data = data.template_file.mysql.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.mysql["username"]}/.ssh/authorized_keys"
      key_data = file(var.mysql["key"])
    }
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "mysql"
  }


}
