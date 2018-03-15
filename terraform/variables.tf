###############################################################################
# REQUIRED PARAMETERS
# These parameters must be passed.
###############################################################################
# AWS Account Settings
variable "aws_account" {}
variable "aws_region" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "r53_zone_name" {}
# Public Subnets
variable "public-1_create" {}
variable "public-1_subnet_cidr" {}
# Private Subnets
variable "private-1_create" {}
variable "private-2_create" {}
variable "private-1_subnet_cidr" {}
variable "private-2_subnet_cidr" {}

variable "bastion_amis" {
  description = "Base AMI to launch the instances with"
  default = {
    "us-east-1" = "ami-f652979b"
    "us-east-2" = "ami-fcc19b99"
    "us-west-1" = "ami-16efb076"
    "us-west-2" = "ami-a58d0dc5"
    "ap-northeast-1" = "ami-c68fc7a1"
    "ap-northeast-2" = "ami-93d600fd"
  }
}

variable "cred-file" {
  default = "~/.aws/credentials-dev"
}

variable "environment" {
  default = "dev"
}

variable "key_name" {
  description = "The aws keypair to use"
  default = "~/.ssh/dev_key"
}

variable "public_key_name" {
  description = "The aws keypair to use"
  default = "~/.ssh/dev_key.pub"
}

variable "availability_zone" {
  description = "The AZ that the resources will be launched"
  default = "us-west-1a"
}

# Web
variable "web_instance_count" {
  description = "The total of web instances to run"
  default  = 2
}
