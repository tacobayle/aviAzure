resource "azurerm_virtual_network" "vn" {
  name     = var.azure["vnetName"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.azure["vnetCidr"]]
}

resource "azurerm_route_table" "rt" {
  count = length(var.subnetNames)
  name = "rt-${element(var.subnetNames, count.index)}"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false
}

resource "azurerm_subnet" "subnet" {
  depends_on = [azurerm_network_security_rule.sgRule]
  count = length(var.subnetNames)
  name = element(var.subnetNames, count.index)
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes = [element(var.subnetCidrs, count.index)]
}

resource "azurerm_subnet_network_security_group_association" "sgSubnetAssociation" {
  count = length(var.subnetNames)
  subnet_id                 = azurerm_subnet.subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.sg.id
}

resource "azurerm_subnet_route_table_association" "rtSubnetAssociation" {
  count = length(var.subnetNames)
  subnet_id                 = azurerm_subnet.subnet[count.index].id
  route_table_id = azurerm_route_table.rt[count.index].id
}

resource "azurerm_public_ip" "natGwIp" {
  name = "natGwIp"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.azure["rgLocation"]
  allocation_method = "Static"
  sku                 = "Standard"
  tags = {
    createdBy = "Terraform"
  }
}

resource "azurerm_nat_gateway" "natGw" {
  name                = "natGateway"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_nat_gateway_public_ip_association" "natGwPublicIpAssociation" {
  nat_gateway_id       = azurerm_nat_gateway.natGw.id
  public_ip_address_id = azurerm_public_ip.natGwIp.id
}

resource "azurerm_subnet_nat_gateway_association" "natGwAssociation" {
  subnet_id      = azurerm_subnet.subnet[1].id
  nat_gateway_id = azurerm_nat_gateway.natGw.id
}
