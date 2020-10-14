resource "azurerm_dns_a_record" "controller" {
  name                = var.controller["hostname"]
  zone_name           = var.azure["dnsZoneName"]
  resource_group_name = var.azure["rgNameDns"]
  ttl                 = 60
  records             = [ azurerm_public_ip.controllerPublicIp.ip_address ]
}

resource "azurerm_dns_a_record" "jump" {
  name                = var.jump["hostname"]
  zone_name           = var.azure["dnsZoneName"]
  resource_group_name = var.azure["rgNameDns"]
  ttl                 = 60
  records             = [ azurerm_public_ip.jumpPublicIp.ip_address ]
}
