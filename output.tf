output "bastion" {
  value = "ssh ${module.bastion.user}@${module.bastion.public_dns}"
}

/*output "puppet" {
  value = "ssh centos@${aws_instance.puppet.private_ip}"
}*/