variable "subnet" {
  description = "AWS Subnet to create bastion host in"
}

variable "ssh_pub_key" {
  description = "Public SSH Key for connecting to bastion host"
  type = string
  sensitive = true
}

variable "aws_region" {
  description = "AWS Region"
}

variable "security_groups" {
  description = "AWS Security Group IDs for bastion host"
  type = list(string)
}

variable "iam_role" {
  description = "EC2 IAM Role for bastion host. Must include createTags for EC2 resources and importKeyPair"
  type = string
}
