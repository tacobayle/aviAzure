
output "jumpPublicIp" {
  value = azurerm_public_ip.jumpPublicIp.ip_address
}

output "aviControllerPublicIp" {
  value = azurerm_public_ip.controllerPublicIp.ip_address
}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.privateKey)} -t ubuntu@${azurerm_public_ip.jumpPublicIp.ip_address} 'git clone ${var.ansible["aviPbAbsentUrl"]} --branch ${var.ansible["aviPbAbsentTag"]}; ansible-playbook ansiblePbAviAbsent/local.yml --extra-vars @${var.ansible["yamlFile"]} --extra-vars @${var.controller["aviCredsJsonFile"]} --extra-vars @${var.ansible["jsonFile"]}' ; sleep 20 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}
