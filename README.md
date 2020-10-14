# aviAzure

## Goals
Spin up a full Azure/Avi environment through Terraform

## Prerequisites:
1. Make sure terraform in installed in the orchestrator VM
2. Make sure Azure credential/details are configured as environment variable:
```
avi@ansible:~$ env | grep ARM
ARM_SUBSCRIPTION_ID=**********************************
ARM_CLIENT_SECRET=**********************************
ARM_TENANT_ID=**********************************
ARM_CLIENT_ID=**********************************
avi@ansible:~$
```

```
avi@ansible:~$ az vm image accept-terms --urn avi-networks:avi-vantage-adc:avi-vantage-se-2001-byol:20.01.01
This command has been deprecated and will be removed in version '3.0.0'. Use 'az vm image terms accept' instead.
```


## Environment:

This has been tested against:

### terraform

```
avi@ansible:~$ terraform -v
Terraform v0.12.21

Your version of Terraform is out of date! The latest version
is 0.12.26. You can update by downloading from https://www.terraform.io/downloads.html
avi@ansible:~$
```

### Avi version

```
Avi 20.1.1
```

### Azure Region:

West Europe

## Input/Parameters:

1. All the paramaters/variables are stored in variables.tf

## Use the the terraform script to:
1. Create RG, vnet,


## Run the terraform:
```
terraform apply -auto-approve
terraform destroy -auto-approve
```

## Improvement (dev branch):

### dev branch:

### future devlopment:
