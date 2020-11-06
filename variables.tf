variable "azure" {
  type = map
  default = {
    rgName = "rg-avi"
    rgLocation = "West Europe"
    vnetName = "vnet-avi"
    vnetCidr = "172.16.0.0/19"
    sgName = "sgAvi"
    rgNameDns = "rg-dns"
    dnsZoneName = "azure.avidemo.fr"
  }
}

variable "azure_client_id_ro" {}
variable "azure_client_secret_ro" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}

variable "subnetNames" {
  type = list
  default = ["subnetMgt", "subnetBackend", "subnetVip"]
}

variable "subnetCidrs" {
  type = list
  default = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

#### Azure securityRule

variable "sgRuleNames" {
  type = list
  default = ["ssh", "tcpdns", "http", "https", "sql", "tcp8443", "tcp5098", "udpdns", "udp123"]
}

variable "sgRuleDestPorts" {
  type = list
  default = ["22", "53", "80", "443", "3306", "8483", "5098", "53", "123"]
}

variable "sgRuleProtocols" {
  type = list
  default = ["tcp", "tcp", "tcp", "tcp", "tcp", "tcp", "tcp", "udp", "udp"]
}

variable "privateKey" {
  default = "~/.ssh/cloudKey"
}

variable "mysql" {
  type = map
  default = {
    type = "Standard_B1s"
    userdata = "userdata/mysql.sh"
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
    username = "ubuntu"
    key = "~/.ssh/cloudKey.pub"
  }
}

variable "opencart" {
  type = map
  default = {
    type = "Standard_B1s"
    userdata = "userdata/opencart.sh"
    hostname = "opencart"
    count = "2"
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
    username = "ubuntu"
    key = "~/.ssh/cloudKey.pub"
    opencartDownloadUrl = "https://github.com/opencart/opencart/releases/download/3.0.3.5/opencart-3.0.3.5.zip"
  }
}

variable "backend" {
  type = map
  default = {
    type = "Standard_B1s"
    userdata = "userdata/backend.sh"
    hostname = "backend"
    count = "3"
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
    username = "ubuntu"
    key = "~/.ssh/cloudKey.pub"
  }
}

variable "scaleset" {
  type = map
  default = {
    type = "Standard_B1s"
    userdata = "userdata/scaleset.sh"
    name = "scaleSet"
    hostname = "backend"
    count = "2"
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
    username = "ubuntu"
    key = "~/.ssh/cloudKey.pub"
  }
}

variable "jump" {
  type = map
  default = {
    hostname = "jump"
    type = "Standard_D2s_v3"
    userdata = "userdata/jump.sh"
    offer = "UbuntuServer"
    publisher = "Canonical"
    sku = "18.04-LTS"
    version = "latest"
    username = "ubuntu"
    key = "~/.ssh/cloudKey.pub"
    avisdkVersion = "18.2.9"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    prefixGroup = "azure"
    aviPbAbsentUrl = "https://github.com/tacobayle/ansiblePbAviAbsent"
    aviPbAbsentTag = "v1.43"
    directory = "ansible"
    aviConfigureTag = "v2.86"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    opencartInstallUrl = "https://github.com/tacobayle/ansibleOpencartInstall"
    opencartInstallTag = "v1.2"
    jsonFile = "~/ansible/vars/fromTf.json"
    yamlFile = "~/ansible/vars/fromTf.yml"
  }
}

variable "controller" {
  default = {
    environment = "AZURE"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    hostname = "controller"
    type = "Standard_DS4_v2"
    offer = "avi-vantage-adc"
    publisher = "avi-networks"
    sku = "avi-vantage-adc-2001"
    version = "20.01.01"
    aviVersion = "20.1.1"
    count = "1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/ansible/vars/creds.json"
  }
}

variable "avi_password" {}
variable "avi_user" {}

variable "avi_cloud" {
  type = map
  default = {
    name = "cloudAzure" # don't change this name
  }
}

variable "serviceEngineGroup" {
  default = [
    {
      name = "Default-Group"
      cloud_ref = "cloudAzure"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = 1
      buffer_se = 0
      realtime_se_metrics = {
        enabled = true
        duration = 0
      }
    },
    {
      name = "seGroupCpuAutoScale"
      cloud_ref = "cloudAzure"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = 1
      buffer_se = 1
      auto_rebalance = true
      auto_rebalance_interval = 30
      auto_rebalance_criteria = [
        "SE_AUTO_REBALANCE_CPU"
      ]
      realtime_se_metrics = {
        enabled = true
        duration = 0
      }
    },
    {
      name: "seGroupGslb"
      cloud_ref = "cloudAzure"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs: 1
      buffer_se: 0
      instance_flavor = "Standard_D2s_v3"
      extra_shared_config_memory = 2000
      accelerated_networking = false
      realtime_se_metrics = {
        enabled: true
        duration: 0
      }
    }
  ]
}

variable "avi_pool" {
  type = map
  default = {
    name = "pool1"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
  }
}

variable "avi_pool_group" {
  type = map
  default = {
    name = "pool2BasedOnAzureScaleSet"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
  }
}

variable "avi_pool_opencart" {
  type = map
  default = {
    name = "poolOpencart"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    application_persistence_profile_ref = "System-Persistence-Client-IP"
  }
}

variable "avi_virtualservice" {
  default = {
    http = [
      {
        name = "app1"
        pool_ref = "pool1"
        cloud_ref = "cloudAzure"
        services: [
          {
            port = 80
            enable_ssl = "false"
          },
          {
            port = 443
            enable_ssl = "true"
          }
        ]
      },
      {
        name = "app2-scaleSet"
        pool_ref = "pool2BasedOnAzureScaleSet"
        cloud_ref = "cloudAzure"
        services: [
          {
            port = 443
            enable_ssl = "true"
          }
        ]
      },
      {
        name = "opencart"
        pool_ref = "poolOpencart"
        cloud_ref = "cloudAzure"
        services: [
          {
            port = 80
            enable_ssl = "false"
          },
          {
            port = 443
            enable_ssl = "true"
          }
        ]
      }
    ],
    dns = [
      {
        name = "app3-dns"
        cloud_ref = "cloudAzure"
        services: [
          {
            port = 53
          }
        ]
      },
      {
        name = "app4-gslb"
        cloud_ref = "cloudAzure"
        services: [
          {
            port = 53
          }
        ]
        se_group_ref: "seGroupGslb"
      }
    ]
  }
}

variable "domain" {
  type = map
  default = {
    name = "azure.avidemo.fr"
  }
}

variable "avi_gslb" {
  type = map
  default = {
    domain = "gslb.avidemo.fr"
  }
}
