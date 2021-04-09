# Terraform Puppet Environment

## Purpose

This terraform module will stand up a proof of concept VPC with public and
private subnets. The private subnets will have a puppet server and application
servers. The public subnet will house a bastion host that can connect via SSH
to the application servers on the private subnet.

## Usage

In order to use, you need two key pairs. One to connect to the bastion host,
and another for the bastion host to connect to the application servers. The
public key for the connection to the bastion host, as well as public and
private keys for connection from the bastion host to the application servers
need to be specified in a `terraform.tfvars` file. An example variable file is
included for ease of set up. Once the variables are in place, run `terraform
apply`. When you're done, run `terraform destroy` to avoid the AWS bills.
