#!/bin/bash
sudo apt-get update
sudo apt install -y python3-pip
sudo apt install -y python-pip
sudo apt install -y jq
sudo apt install -y python-jmespath
pip install ansible==${ansibleVersion}
pip install ansible[azure]==${ansibleVersion}
pip install avisdk==${avisdkVersion}
pip install 'ansible[azure]'
pip install dnspython
# pip3 install requests
# pip3 install google-auth
# pip3 install dnspython
# pip3 and ubuntu 20.04 seem to bug with google ansible module!!!
sudo -u ubuntu ansible-galaxy install -f avinetworks.avisdk
sudo mkdir -p /opt/ansible/inventory
sudo chmod -R 757 /opt/ansible/inventory
sudo tee /opt/ansible/inventory/inventory.azure_rm.yaml > /dev/null <<EOT
---
plugin: azure_rm
include_vm_resource_groups:
  - ${rg}
auth_source: auto

keyed_groups:
  - prefix: ${ansiblePrefixGroup}
    key: tags
EOT
#sudo chmod -R 755 /opt/ansible
sudo mkdir -p /etc/ansible
sudo tee /etc/ansible/ansible.cfg > /dev/null <<EOT
[defaults]
inventory      = /opt/ansible/inventory/inventory.azure_rm.yaml
private_key_file = /home/${username}/.ssh/${basename(privateKey)}
host_key_checking = False
host_key_auto_add = True
EOT
mkdir -p /home/${username}/.azure
tee /home/${username}/.azure/credentials > /dev/null <<EOT
[default]
subscription_id=${azure_subscription_id}
client_id=${azure_client_id}
secret=${azure_client_secret}
tenant=${azure_tenant_id}
EOT
echo "cloud init done" | tee /tmp/cloudInitDone.log
