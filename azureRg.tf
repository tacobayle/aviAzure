resource "azurerm_resource_group" "rg" {
  name     = var.azure["rgName"]
  location = var.azure["rgLocation"]
}
