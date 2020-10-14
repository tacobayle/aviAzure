resource "azurerm_network_security_group" "sg" {
  name = var.azure["sgName"]
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "sgRule" {
  depends_on = [azurerm_network_security_group.sg]
  count = length(var.sgRuleNames)
  name = element(var.sgRuleNames, count.index)
  priority = "10${count.index}"
  direction = "Inbound"
  access = "Allow"
  protocol = element(var.sgRuleProtocols, count.index)
  source_port_range = "*"
  destination_port_range = element(var.sgRuleDestPorts, count.index)
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg.name
}
