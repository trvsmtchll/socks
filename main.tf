# AWS VPC
resource "aviatrix_vpc" "East2-VPC2" {
  cloud_type           = 1
  account_name         = var.aws_account_name
  region               = "us-east-2"
  name                 = "East2-VPC2"
  cidr                 = "10.106.0.0/16"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
}

# AWS Instance
resource "aws_instance" "test_instance" {
  key_name                    = var.key_name
  ami                         = data.aws_ami.ubuntu_server.id
  instance_type               = "t2.micro"
  subnet_id                   = aviatrix_vpc.East2-VPC2.subnets[4].subnet_id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_icmp_onprem.id]
  associate_public_ip_address = true

  tags = {
    environment = "Aviatrix-POC"
    Name = "socks-poc-${var.aws_region}-vm"
  }
}

data "aws_ami" "ubuntu_server" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["*ubuntu-xenial-16.04-amd64-server-20181114*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "allow_ssh_icmp_onprem" {
  name        = "allow_ssh_icmp"
  description = "Allow SSH & ICMP onprem traffic"
  vpc_id      = aviatrix_vpc.East2-VPC2.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Azure VNET
resource "aviatrix_vpc" "East-VNET1" {
  cloud_type           = 8
  account_name         = var.azure_account_name
  region               = "East US"
  name                 = "East-VNET1"
  cidr                 = "10.120.0.0/16"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
}

# Retrieve Azure VNET details
data "aviatrix_vpc" "East-VNET1" {
  name = aviatrix_vpc.East-VNET1.name
}

output "avx_azure_vpc_id" {
  value = data.aviatrix_vpc.East-VNET1.vpc_id
}

output "azure_rg" {
  value = "${split(":", data.aviatrix_vpc.East-VNET1.vpc_id)[1]}"
}

output "azure_vnet_name" {
  value = "${split(":", data.aviatrix_vpc.East-VNET1.vpc_id)[0]}"
}

data "azurerm_subnet" "avx_vnet" {
  name                 = aviatrix_vpc.East-VNET1.subnets[1].subnet_id
  virtual_network_name = "${split(":", data.aviatrix_vpc.East-VNET1.vpc_id)[0]}" 
  resource_group_name  = "${split(":", data.aviatrix_vpc.East-VNET1.vpc_id)[1]}"
}

output "subnet_id" {
  value = data.azurerm_subnet.avx_vnet.id
}

# Azure RG + Instance - your own RG
resource "azurerm_resource_group" "example" {
  name     = "socks-poc-rg"
  location = "East US"
}

module "linuxservers" {
  source                        = "Azure/compute/azurerm"
  resource_group_name           = azurerm_resource_group.example.name
  vm_hostname                   = "socksvm"
  nb_public_ip                  = 0
  remote_port                   = "22"
  nb_instances                  = 1
  vm_os_publisher               = "Canonical"
  vm_os_offer                   = "UbuntuServer"
  vm_os_sku                     = "18.04-LTS"
  vnet_subnet_id                = "${data.azurerm_subnet.avx_vnet.id}" 
  boot_diagnostics              = true
  delete_os_disk_on_termination = true
  nb_data_disk                  = 2
  data_disk_size_gb             = 64
  data_sa_type                  = "Premium_LRS"
  enable_ssh_key                = true
  vm_size                       = "Standard_D4s_v3"
  
  tags = {
    environment = "Aviatrix-POC"
    name        = "socks-poc-eastus-vm"
  }

  enable_accelerated_networking = false
}

output "azure_linux_vm_private_ip" {
  value = module.linuxservers.network_interface_private_ip
}
/*
output "aws_linux_vm_private_ip"   {
  value = resource.aws_instance.test_instance.private_ip
}
*/
