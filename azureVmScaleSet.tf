data "template_file" "scaleSet" {
  template = file(var.scaleset["userdata"])
}

resource "azurerm_linux_virtual_machine_scale_set" "scaleSet" {
  name                = var.scaleset["name"]
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.azure["rgLocation"]
  sku                 = var.scaleset["type"]
  instances           = var.scaleset["count"]
  admin_username      = var.scaleset["username"]

  admin_ssh_key {
    username   = var.scaleset["username"]
    public_key = file(var.scaleset["key"])
  }

  source_image_reference {
    publisher = var.scaleset["publisher"]
    offer     = var.scaleset["offer"]
    sku       = var.scaleset["sku"]
    version   = var.scaleset["version"]
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  custom_data = base64encode(data.template_file.scaleSet.rendered)


  network_interface {
    name    = "nicScaleSet"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.1.id
    }
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "scale set"
  }
}
