terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"
  default     = "10.1.0.0/16"
}

variable "ssh_pub_key" {
  description = "SSH Public Key for bastion host"
  type        = string
  sensitive   = true
}

output "bastion_dns" {
  value = aws_instance.bastion.public_dns
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "TF Puppet"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "app_host" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  tags = {
    Name = "app_host"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "ngw" {
  vpc = true
  tags = {
    Name = "NAT Gateway IP"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.app_host.id
  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_key_pair" "local" {
  key_name   = "bastion-key"
  public_key = var.ssh_pub_key
  tags = {
    Name = "Bastion Key"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.local.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "Bastion"
  }
}
