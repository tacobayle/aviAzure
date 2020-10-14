resource "azurerm_virtual_network" "vn" {
  name     = var.azure["vnetName"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.azure["vnetCidr"]]
}
