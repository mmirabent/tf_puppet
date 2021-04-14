output "key_pair_name" {
  description = "Key pair name for connections from bastion host"
  value = local.key_pair_name
}

output "public_dns" {
  description = "Public DNS name of the bastion host"
  value = aws_instance.bastion.public_dns
}

output "user" {
  description = "User used to log into the bastion host"
  value = local.user
}
