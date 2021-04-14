terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

module "network" {
  source = "./modules/network"
  
  base_cidr_block = var.base_cidr_block
}

module "bastion" {
  source = "./modules/bastion"
  
  subnet = module.network.public_subnet
  ssh_pub_key = var.ssh_pub_key
  aws_region = var.aws_region
  security_groups = [module.network.public_security_group.id]
  iam_role = var.ec2_iam_role
}
