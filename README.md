# socks

## Summary

Example to build AWS VPC, Azure VNET and create instances in each using aws +azurerm TF provider

## Prerequisites

- AWS cli / ENV vars configured in your environment
- Azure cli / ENV vars configured in your environment
- terraform .12
- Aviatrix Controller with Access Accounts defined for AWS + Azure

## To run it

- ```terraform init```
- ```terraform plan```
- ```terraform apply --auto-approve```
- To Destroy ```terraform destroy --auto-approve```

## What to expect

This example will build a VPC and a VNET, and launch instances in them.

**_Note:_** In azure this will create a seperate Resource Group for you to manage VMs seperately