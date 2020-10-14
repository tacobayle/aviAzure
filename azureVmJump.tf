resource "azurerm_public_ip" "jumpPublicIp" {
  name = "jumpPublicIp"
  resource_group_name = azurerm_resource_group.rg.name
  location = var.azure["rgLocation"]
  sku                 = "Standard"
  allocation_method = "Static"
  tags = {
    createdBy = "Terraform"
  }
}

resource "azurerm_network_interface" "nicJump" {
  depends_on = [azurerm_network_security_rule.sgRule, azurerm_subnet.subnet]
  name = "nic-jump"
  location = var.azure["rgLocation"]
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpPublicIp.id
  }
  tags = {
    createdBy = "Terraform"
  }
}

data "template_file" "jump" {
  template = file(var.jump["userdata"])
  vars = {
    avisdkVersion = var.jump["avisdkVersion"]
    ansibleVersion = var.ansible["version"]
    ansiblePrefixGroup = var.ansible["prefixGroup"]
    privateKey = var.privateKey
    username = var.jump["username"]
    rg = var.azure["rgName"]
    azure_client_id = var.azure_client_id_ro
    azure_client_secret = var.azure_client_secret_ro
    azure_subscription_id = var.azure_subscription_id
    azure_tenant_id = var.azure_tenant_id
  }
}



resource "azurerm_virtual_machine" "jump" {
  depends_on = [azurerm_network_interface.nicJump, azurerm_virtual_machine.controller]
  name          = var.jump["hostname"]
  location                  = var.azure["rgLocation"]
  resource_group_name       = azurerm_resource_group.rg.name
  vm_size                   = var.jump["type"]
  network_interface_ids     = [ azurerm_network_interface.nicJump.id ]

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

# az vm image list --output table

  storage_image_reference {
    publisher = var.jump["publisher"]
    offer     = var.jump["offer"]
    sku       = var.jump["sku"]
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.jump["hostname"]}_ssd"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }


  os_profile {
    computer_name   = var.jump["hostname"]
    admin_username = var.jump["username"]
    custom_data = data.template_file.jump.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.jump["username"]}/.ssh/authorized_keys"
      key_data = file(var.jump["key"])
    }
  }

  tags = {
    createdBy                         = "Terraform"
    group                     = "jump"
  }

  connection {
    host        = azurerm_public_ip.jumpPublicIp.ip_address
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file(var.privateKey)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }

  # to copy  ansible directory

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

avi_systemconfiguration:
  global_tenant_config:
    se_in_provider_context: false
    tenant_access_to_provider_se: true
    tenant_vrf: false
  welcome_workflow_complete: true
  ntp_configuration:
    ntp_servers:
      - server:
          type: V4
          addr: ${var.controller["ntpMain"]}
  dns_configuration:
    search_domain: ''
    server_list:
      - type: V4
        addr: ${var.controller["dnsMain"]}
  email_configuration:
    from_email: test@avicontroller.net
    smtp_type: SMTP_LOCAL_HOST

controllerPrivateIps:
${yamlencode(azurerm_network_interface.nicController.*.private_ip_address)}

controllerPublicIps:
${yamlencode(azurerm_public_ip.controllerPublicIp.*.ip_address)}

azure:
  subscription_id: ${var.azure_subscription_id}
  resource_group: ${var.azure["rgName"]}
  use_managed_disks: true
  use_enhanced_ha: false
  cloud_credentials_ref: credsAzure
  use_azure_dns: true
  location: ${replace(lower(var.azure["rgLocation"]), " ", "")}
  use_standard_alb: false
  cloudName: &cloud0 cloudAzure # don't modify it

azureSubnets:
  mgt:
    - se_network_id: ${var.subnetNames[0]}
      virtual_network_id: ${azurerm_virtual_network.vn.id}
      type: V4
  vip:
    - vip_network_id: ${var.subnetNames[2]}
      vip_network_cidr: ${var.subnetCidrs[2]}
      type: V4

serviceEngineGroup:
  - name: &segroup0 Default-Group
    cloud_ref: *cloud0
    ha_mode: HA_MODE_SHARED
    min_scaleout_per_vs: 1
    buffer_se: 0
    #instance_flavor: t3.large
    #extra_shared_config_memory: 0
    realtime_se_metrics:
      enabled: true
      duration: 0
  - name: &segroup1 seGroupCpuAutoScale
    cloud_ref: *cloud0
    ha_mode: HA_MODE_SHARED
    min_scaleout_per_vs: 1
    buffer_se: 1
    #instance_flavor: t2.micro
    #extra_shared_config_memory: 0
    auto_rebalance: true
    auto_rebalance_interval: 30
    auto_rebalance_criteria:
    - SE_AUTO_REBALANCE_CPU
    realtime_se_metrics:
      enabled: true
      duration: 0
  - name: &segroup2 seGroupGslb
    cloud_ref: *cloud0
    ha_mode: HA_MODE_SHARED
    min_scaleout_per_vs: 1
    buffer_se: 0
    instance_flavor: Standard_D2s_v3
    extra_shared_config_memory: 2000
    realtime_se_metrics:
      enabled: true
      duration: 0

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

avi_healthmonitor:
  - name: &hm0 hm1
    receive_timeout: 1
    failed_checks: 2
    send_interval: 1
    successful_checks: 2
    type: HEALTH_MONITOR_HTTP
    http_request: "HEAD / HTTP/1.0"
    http_response_code:
      - HTTP_2XX
      - HTTP_3XX
      - HTTP_5XX

avi_pool:
  name: &pool0 pool1
  lb_algorithm: LB_ALGORITHM_ROUND_ROBIN
  health_monitor_refs: *hm0
  cloud_ref: *cloud0

avi_pool_group:
  - name: &pool1 pool2BasedOnAwsAutoScalingGroup
    autoscale_policy_ref: *autoscalepolicy0
    external_autoscale_groups: ${azurerm_linux_virtual_machine_scale_set.scaleSet.id}
    health_monitor_refs: *hm0
    cloud_ref: *cloud0

avi_pool_open_cart:
  name: &pool2 poolOpencart
  lb_algorithm: LB_ALGORITHM_ROUND_ROBIN
  health_monitor_refs: *hm0
  application_persistence_profile_ref: System-Persistence-Client-IP
  cloud_ref: *cloud0

avi_virtualservice:
  http:
    - name: &vs0 app1
      pool_ref: *pool0
      cloud_ref: *cloud0
      services:
        - port: 80
          enable_ssl: false
        - port: 443
          enable_ssl: true
    - name: &vs1 app2-basedOnScaleSet
      pool_ref: *pool1
      cloud_ref: *cloud0
      services:
        - port: 443
          enable_ssl: true
    - name: &vs2 opencart
      pool_ref: *pool2
      cloud_ref: *cloud0
      services:
        - port: 443
          enable_ssl: true
  dns:
    - name: app3-dns
      cloud_ref: *cloud0
      services:
        - port: 53
    - name: app4-gslb
      cloud_ref: *cloud0
      services:
        - port: 53
      se_group_ref: *segroup2

domain:
  name: ${var.domain["name"]}

avi_gslb:
  dns_configs:
    - domain_name: ${var.avi_gslb["domain"]}

EOF
  destination = "~/ansible/vars/fromTerraform.yml"
  }


  provisioner "remote-exec" {
    inline      = [
    "echo toto ; env | grep AZURE ; echo toto",
    "cat ~/ansible/vars/fromTerraform.yml",
    "ansible-inventory --graph",
    "chmod 600 ${var.privateKey}",
    "cd ~/ansible ; git clone ${var.ansible["opencartInstallUrl"]} --branch ${var.ansible["opencartInstallTag"]} ; ansible-playbook ansibleOpencartInstall/local.yml --extra-vars @vars/fromTerraform.yml",
    "cd ~/ansible ; git clone ${var.ansible["aviConfigureUrl"]} --branch ${var.ansible["aviConfigureTag"]} ; ansible-playbook aviConfigure/local.yml --extra-vars @vars/fromTerraform.yml",
    ]
  }
}
