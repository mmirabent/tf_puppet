# EC2 Resources

# This has to match the local user for the bastion host. In the case of Amazon
# Linux this is ec2-user
locals {
  bastion_user = "ec2-user"
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

data "aws_ami" "centos8" {
  owners = ["aws-marketplace"]

  # https://wiki.centos.org/Cloud/AWS#Official_and_current_CentOS_Public_Images
  filter {
    name   = "product-code"
    values = ["47k9ia2igxpcce2bzo8u3kj03"]
  }
}

data "cloudinit_config" "bastion" {
  part {
    content_type = "text/cloud-config"
    content      = <<-EOT
      preserve_hostname: false
      hostname: bastion
      fqdn: bastion.local
      manage_etc_hosts: true
    EOT

    /*write_files:
        - encoding: b64
          content: "${base64encode(var.ssh_internal_priv)}"
          path: "/run/ssh_tmp/id_rsa"
          permissions: "0600"
    EOT*/
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
      su - ec2-user -c 'yes y | ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
      export KEY_PAIR_ID=$(aws ec2 import-key-pair --region "${var.aws_region}" --key-name "internal" --public-key-material fileb://~ec2-user/.ssh/id_rsa.pub --query KeyPairId)
      export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
      aws ec2 create-tags --region "${var.aws_region}" --resources $INSTANCE_ID --tags "Key=KeyPairID,Value=$KEY_PAIR_ID"
    EOT
    /*yum update -y
      mv "/run/ssh_tmp/id_rsa" "/home/${local.bastion_user}/.ssh/id_rsa"
      chown -v "${local.bastion_user}:${local.bastion_user}" "/home/${local.bastion_user}/.ssh/id_rsa"
    EOT*/
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = var.ssh_pub_key
  tags = {
    Name = "Bastion Key"
  }
}

/*resource "aws_key_pair" "internal" {
  key_name   = "tf-puppet-internal"
  public_key = var.ssh_internal_pub
  tags = {
    Name = "TF Puppet Internal Key"
  }
}*/

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data_base64       = data.cloudinit_config.bastion.rendered
  iam_instance_profile   = var.ec2_iam_role

  tags = {
    Name = "Bastion"
  }
}

/*resource "null_resource" "internal_ssh_key" {

}*/

/*resource "aws_instance" "puppet" {
  ami                    = data.aws_ami.centos8.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.internal.key_name
  subnet_id              = aws_subnet.app_host.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data_base64       = base64encode(templatefile("${path.module}/templates/puppet_user_data.txt", { hostname = "puppet" }))

  tags = {
    Name = "Puppet"
  }
}*/