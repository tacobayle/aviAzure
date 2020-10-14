resource "azurerm_network_interface" "nicOpencart" {
  count = var.opencart["count"]
  depends_on = [azurerm_network_security_rule.sgRule, azurerm_subnet.subnet]
  name = "nic-opencart${count.index}"
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

data "template_file" "opencart" {
  template = file(var.opencart["userdata"])
  vars = {
    opencartDownloadUrl = var.opencart["opencartDownloadUrl"]
    domainName = var.avi_gslb["domain"]
  }

}


resource "azurerm_virtual_machine" "opencart" {
  depends_on = [azurerm_network_interface.nicOpencart]
  count = var.opencart["count"]
  name          = "opencart-${count.index + 1 }"
  location                  = var.azure["rgLocation"]
  resource_group_name       = azurerm_resource_group.rg.name
  vm_size                   = var.opencart["type"]
  network_interface_ids     = [ azurerm_network_interface.nicOpencart[count.index].id ]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

# az vm image list --output table

  storage_image_reference {
    publisher = var.opencart["publisher"]
    offer     = var.opencart["offer"]
    sku       = var.opencart["sku"]
    version   = "latest"
  }

  storage_os_disk {
    name              = "opencart-${count.index + 1 }-ssd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }


  os_profile {
    computer_name   = "opencart-${count.index + 1 }"
    admin_username = var.opencart["username"]
    custom_data = data.template_file.opencart.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.opencart["username"]}/.ssh/authorized_keys"
      key_data = file(var.opencart["key"])
    }
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "opencart"
  }

}
