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

variable "ec2_iam_role" {
  description = "IAM Role for EC2 instances, must include S3 access"
}