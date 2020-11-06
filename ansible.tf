resource "null_resource" "foo7" {
  depends_on = [azurerm_virtual_machine.jump]

  connection {
    host = azurerm_public_ip.jumpPublicIp.ip_address
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = file(var.privateKey)
  }

  provisioner "file" {
    source      = var.privateKey
    destination = "~/.ssh/${basename(var.privateKey)}"
  }

  provisioner "file" {
    source      = var.ansible["directory"]
    destination = "~/ansible"
  }

  provisioner "file" {
    content      = <<EOF
---
mysql_db_hostname: ${azurerm_network_interface.nicMysql.private_ip_address}

controller:
  environment: ${var.controller["environment"]}
  username: ${var.avi_user}
  password: ${var.avi_password}
  version: ${var.controller["aviVersion"]}
  count: ${var.controller["count"]}
  from_email: ${var.controller["from_email"]}
  se_in_provider_context: ${var.controller["se_in_provider_context"]}
  tenant_access_to_provider_se: ${var.controller["tenant_access_to_provider_se"]}
  tenant_vrf: ${var.controller["tenant_vrf"]}
  aviCredsJsonFile: ${var.controller["aviCredsJsonFile"]}

controllerPrivateIps:
${yamlencode(azurerm_network_interface.nicController.*.private_ip_address)}

controllerPublicIps:
${yamlencode(azurerm_public_ip.controllerPublicIp.*.ip_address)}

ntpServers:
${yamlencode(var.controller["ntp"].*)}

dnsServers:
${yamlencode(var.controller["dns"].*)}

azure:
  subscription_id: ${var.azure_subscription_id}
  resource_group: ${var.azure["rgName"]}
  use_managed_disks: true
  use_enhanced_ha: false
  cloud_credentials_ref: credsAzure
  use_azure_dns: true
  location: ${replace(lower(var.azure["rgLocation"]), " ", "")}
  use_standard_alb: false
  cloudName: &cloud0 ${var.avi_cloud["name"]}

azureSubnets:
  mgt:
    - se_network_id: ${var.subnetNames[0]}
      virtual_network_id: ${azurerm_virtual_network.vn.id}
      type: V4
  vip:
    - vip_network_id: ${var.subnetNames[2]}
      vip_network_cidr: ${var.subnetCidrs[2]}
      type: V4

avi_applicationprofile:
  http:
    - name: &appProfile0 applicationProfileOpencart

avi_serverautoscalepolicy:
  - name: &autoscalepolicy0 autoscalepolicyAsg
    min_size: 2
    max_size: 2
    max_scaleout_adjustment_step: 2
    max_scalein_adjustment_step: 2
    scaleout_cooldown: 30
    scalein_cooldown: 30

avi_servers:
${yamlencode(azurerm_network_interface.nicBackend.*.private_ip_address)}

avi_servers_open_cart:
${yamlencode(azurerm_network_interface.nicOpencart.*.private_ip_address)}

avi_pool:
  name: ${var.avi_pool["name"]}
  lb_algorithm: ${var.avi_pool["lb_algorithm"]}
  cloud_ref: ${var.avi_cloud["name"]}

avi_pool_group:
  - name: ${var.avi_pool_group["name"]}
    cloud_ref: ${var.avi_cloud["name"]}
    autoscale_policy_ref: *autoscalepolicy0
    external_autoscale_groups: ${var.scaleset["name"]}@${upper(var.azure["rgName"])}
    lb_algorithm: ${var.avi_pool_group["lb_algorithm"]}

avi_pool_open_cart:
  application_persistence_profile_ref: ${var.avi_pool_opencart["application_persistence_profile_ref"]}
  name: ${var.avi_pool_opencart["name"]}
  lb_algorithm: ${var.avi_pool_opencart["lb_algorithm"]}
  cloud_ref: ${var.avi_cloud["name"]}

domain:
  name: ${var.domain["name"]}

avi_gslb:
  dns_configs:
    - domain_name: ${var.avi_gslb["domain"]}

EOF
  destination = var.ansible["yamlFile"]
}

  provisioner "file" {
    content      = <<EOF
{"serviceEngineGroup": ${jsonencode(var.serviceEngineGroup)}, "avi_virtualservice": ${jsonencode(var.avi_virtualservice)}}
EOF
    destination = var.ansible["jsonFile"]
  }

provisioner "remote-exec" {
  inline      = [
    "cat ${var.ansible["yamlFile"]}",
    "ansible-inventory --graph",
    "chmod 600 ${var.privateKey}",
    "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook ansibleOpencartInstall/local.yml --extra-vars @${var.ansible["yamlFile"]}",
    "cd ~/ansible ; git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]} ; ansible-playbook aviConfigure/local.yml --extra-vars @${var.ansible["yamlFile"]} --extra-vars @${var.ansible["jsonFile"]}",
  ]
}
}