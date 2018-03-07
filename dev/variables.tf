# Main
variable "cred-file" {
  default = "~/.aws/credentials"
}

variable "environment" {
  default = "dev"
}

variable "key_name" {
  description = "The aws keypair to use"
  default = "~/.ssh/dev_key"
}

variable "region" {
  description = "Region that the instances will be created"
  default = "us-west-1"
}

variable "availability_zone" {
  description = "The AZ that the resources will be launched"
  default = "us-west-1a"
}

# Networking
variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  default            = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block of the public subnet"
  default  = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "The CIDR block of the private subnet"
  default = "10.0.2.0/24"
}

# Web
variable "web_instance_count" {
  description = "The total of web instances to run"
  default  = 2
}
