provider "aviatrix" {
    controller_ip      = var.controller_ip
    username           = var.username
    password           = var.password
}

provider "aws" {
    region = "us-east-2"
}

provider "azurerm" {
  version = "~> 2.2"
  features {}
}