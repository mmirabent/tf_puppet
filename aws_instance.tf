data "aws_ami" "centos8" {
  owners = ["aws-marketplace"]

  # https://wiki.centos.org/Cloud/AWS#Official_and_current_CentOS_Public_Images
  filter {
    name   = "product-code"
    values = ["47k9ia2igxpcce2bzo8u3kj03"]
  }
}

data "cloudinit_config" "puppet" {
  part {
    content_type = "text/cloud-config"
    content      = <<-EOT
      preserve_hostname: false
      hostname: bastion
      fqdn: bastion.local
      manage_etc_hosts: true
    EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOT
      yum update -y
      rpm -Uvh "https://yum.puppet.com/puppet7-release-el-8.noarch.rpm"
      yum install -y puppetserver
      yum install -y puppet-agent
      sed -ri 's/(JAVA_ARGS=.*)-Xms2g/\1-Xms512m/' /etc/sysconfig/puppetserver
      sed -ri 's/(JAVA_ARGS=.*)-Xmx2g/\1-Xmx512m/' /etc/sysconfig/puppetserver
      systemctl restart puppetserver
    EOT
  }
}

resource "aws_instance" "puppet" {
  ami                    = data.aws_ami.centos8.id
  instance_type          = "t2.medium"
  key_name               = "tf_puppet-internal"
  subnet_id              = module.network.private_subnet.id
  vpc_security_group_ids = [module.network.public_security_group.id]
  user_data_base64       = data.cloudinit_config.puppet.rendered

  tags = {
    Name = "Puppet"
  }
  
  depends_on = [module.bastion]
}