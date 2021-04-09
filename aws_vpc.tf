resource "aws_vpc" "main" {
  cidr_block           = var.base_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "TF Puppet"
  }
}
