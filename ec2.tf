# EC2 Resources

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

resource "aws_key_pair" "local" {
  key_name   = "bastion-key"
  public_key = var.ssh_pub_key
  tags = {
    Name = "Bastion Key"
  }
}

resource "aws_key_pair" "internal" {
  key_name   = "tf-puppet-internal"
  public_key = var.ssh_internal_pub
  tags = {
    Name = "TF Puppet Internal Key"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.local.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data_base64       = base64encode(templatefile("${path.module}/templates/bastion_user_data.txt", { user = var.user, ssh_priv = base64encode(var.ssh_internal_priv), hostname = "bastion" }))

  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "puppet" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.internal.key_name
  subnet_id              = aws_subnet.app_host.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data_base64       = base64encode(templatefile("${path.module}/templates/hostname_user_data.txt", { hostname = "puppet" }))

  tags = {
    Name = "Puppet"
  }
}