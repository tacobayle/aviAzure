# aviAzure

## Goals
Spin up a full Azure/Avi environment through Terraform

## Prerequisites:
- Make sure terraform in installed in the orchestrator VM
- Make sure Azure credential/details are configured as environment variable:
```
ARM_CLIENT_ID=**********************************
ARM_TENANT_ID=**********************************
ARM_CLIENT_SECRET=**********************************
ARM_SUBSCRIPTION_ID=**********************************
TF_VAR_azure_client_secret_ro=**********************************
TF_VAR_azure_client_id_ro=**********************************
TF_VAR_azure_subscription_id=**********************************
TF_VAR_azure_tenant_id=**********************************
TF_VAR_avi_user=admin
TF_VAR_avi_password==**********************************
```
- Make sure you approved the Avi T&C
```
avi@ansible:~$ az vm image accept-terms --urn avi-networks:avi-vantage-adc:avi-vantage-se-2001-byol:20.01.01
This command has been deprecated and will be removed in version '3.0.0'. Use 'az vm image terms accept' instead.
```

## Environment:
This has been tested against:

### terraform
```
Your version of Terraform is out of date! The latest version
is 0.13.4. You can update by downloading from https://www.terraform.io/downloads.html
Terraform v0.13.0
+ provider registry.terraform.io/hashicorp/azurerm v2.31.1
+ provider registry.terraform.io/hashicorp/template v2.2.0
```

### Avi version
```
Avi 20.1.1
```

### Azure Region:
```
West Europe
```

## Input/Parameters:
- All the paramaters/variables are stored in variables.tf

## Use the the terraform script to:
- Create RG
- Create Vnet, Subnets, Route Table, Security Group, Nat Gw
- Create VMs: Backend, jump, mysql, opencart
- Create a scale set
- Create a yaml variable file - in the jump server
- Call ansible to do the configuration (opencart app) based on dynamic inventory
- Call ansible to do the configuration (avi) based on dynamic inventory
- Register the FQDN of the jump server and the Avi Controller on the hosted zone

## Run the terraform:
```
terraform apply -auto-approve
terraform destroy -auto-approve
```
