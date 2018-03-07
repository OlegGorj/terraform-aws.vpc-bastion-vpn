variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
}

variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zone" {
  description = "The az that the resources will be launched"
}

# Bastion
variable "bastion_instance_type" {
  description = "Type of ec2 instance used for bastion node"
  default            = "t2.micro"
}

variable "bastion_ami" {
  default = {
    "us-east-1" = "ami-f652979b"
    "us-east-2" = "ami-fcc19b99"
    "us-west-1" = "ami-16efb076"
  }
}

variable "key_name" {
  description = "The public key for the bastion host"
}
