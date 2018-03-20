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

variable "azs" {
    type    = "map"
    default = {
        "ap-southeast-2" = "ap-southeast-2a,ap-southeast-2b,ap-southeast-2c"
        "eu-west-1"      = "eu-west-1a,eu-west-1b,eu-west-1c"
        "us-west-1"      = "us-west-1b,us-west-1c"
        "us-west-2"      = "us-west-2a,us-west-2b,us-west-2c"
        "us-east-1"      = "us-east-1c,us-west-1d,us-west-1e"
    }
}
