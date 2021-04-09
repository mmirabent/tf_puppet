output "bastion_dns" {
  value = aws_instance.bastion.public_dns
}

output "puppet_ip" {
  value = aws_instance.puppet.private_ip
}