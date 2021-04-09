output "bastion" {
  value = "ssh ${local.bastion_user}@${aws_instance.bastion.public_dns}"
}

output "puppet" {
  value = "ssh centos@${aws_instance.puppet.private_ip}"
}