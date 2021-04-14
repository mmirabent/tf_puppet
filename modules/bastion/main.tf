# This has to match the local user for the bastion host. In the case of Amazon
# Linux this is ec2-user
locals {
  user = "ec2-user"
  hostname = "bastion"
  domain = "local"
  key_pair_name = "tf_puppet-internal"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "cloudinit_config" "bastion" {
  part {
    content_type = "text/cloud-config"
    content      = <<-EOT
      preserve_hostname: false
      hostname: ${local.hostname}
      fqdn: ${local.hostname}.${local.domain}
      manage_etc_hosts: true
    EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
      su - ec2-user -c 'yes y | ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
      export KEY_PAIR_ID=$(aws ec2 import-key-pair --region "${var.aws_region}" --key-name ${local.key_pair_name} --public-key-material fileb://~${local.user}/.ssh/id_rsa.pub --query KeyPairId)
      export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
      aws ec2 create-tags --region "${var.aws_region}" --resources $INSTANCE_ID --tags "Key=KeyPairID,Value=$KEY_PAIR_ID"
      yum update -y
    EOT
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = var.ssh_pub_key
  tags = {
    Name = "Bastion Key"
  }
}

# Delete the key pair if it already exists before launching bastion host.
# Bastion's user data will import a new key pair
resource "null_resource" "ensure_no_key" {
  provisioner "local-exec" {
    command = "aws ec2 delete-key-pair --key-name ${local.key_pair_name}"
    on_failure = continue
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = var.subnet.id
  vpc_security_group_ids = [for group in var.security_groups : group]
  user_data_base64       = data.cloudinit_config.bastion.rendered
  iam_instance_profile   = var.iam_role

  tags = {
    Name = "Bastion"
    KeyPairName = local.key_pair_name
  }

  depends_on = [null_resource.ensure_no_key]

  lifecycle {
    ignore_changes = [
      tags["KeyPairID"]
    ]
  }

  # Wait for KeyPairID resource tag before considering this resource complete
  provisioner "local-exec" {
    command = <<-EOF
    #!/bin/bash
    key_pair_id=""
    echo "Waiting for KeyPairID"
    while [[ -z "$key_pair_id" ]] ; do
      sleep 5
      key_pair_id=$(aws ec2 describe-tags --region '${var.aws_region}' --filters 'Name=resource-id,Values=${self.id}' 'Name=key,Values=KeyPairID' --output text --query 'Tags[*].Value')
    done
    EOF
  }

  # On destroy, also remove the key-pair uploaded by the user data script
  provisioner "local-exec" {
    when = destroy
    command = "aws ec2 delete-key-pair --key-name ${self.tags["KeyPairName"]}"
    on_failure = continue
  }
}
