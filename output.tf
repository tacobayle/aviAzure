


output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${basename(var.privateKey)} -t ubuntu@${azurerm_public_ip.jumpPublicIp.ip_address} 'git clone ${var.ansible["aviPbAbsentUrl"]} --branch ${var.ansible["aviPbAbsentTag"]}; ansible-playbook ansiblePbAviAbsent/local.yml --extra-vars @~/ansible/vars/fromTerraform.yml --extra-vars @~/ansible/vars/creds.json' ; sleep 20 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}
