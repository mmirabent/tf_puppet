output "private_subnet" {
  description = "Private subnet. Allows only outbound access to the internet, and inbound access only on port 22 and only from within the vpc"
  value = aws_subnet.private
}

output "public_subnet" {
  description = "Public subnet. Allows port 22 in from anywhere and allocates public IPs"
  value = aws_subnet.public
}

output "public_security_group" {
  description = "Security group for public subnet. Allows port 22 from anywhere"
  value = aws_security_group.allow_ssh
}
