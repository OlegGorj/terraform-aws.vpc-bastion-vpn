###############################################################################
# VARIABLES
###############################################################################

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
  default     = "dev"
}

variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zone" {
  description = "The az that the resources will be launched"
}

variable "bastion_instance_type" {
  description = "Type of ec2 instance used for bastion node"
  default     = "t2.micro"
}

variable "bastion_ami" {
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

variable "key_name" {
  description = "The public key for the bastion host"
}

###############################################################################
# RESOURCES
###############################################################################
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

/* Internet gateway for the PUBLIC subnet */
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc = true
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_subnet_cidr}"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name        = "${var.environment}-public-subnet"
    Environment = "${var.environment}"
  }
}

/* Private subnet WEB */
resource "aws_subnet" "private_subnet_web" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.private_subnet_cidr}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.availability_zone}"

  tags {
    Name        = "${var.environment}-private-subnet"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id       = "${aws_subnet.private_subnet_web.id}"
  route_table_id  = "${aws_route_table.private.id}"
}

/* Default security group */
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags {
    Environment = "${var.environment}"
  }
}
###############################################################################
# OUTPUT
###############################################################################

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private_subnet_web.id}"
}

output "default_sg_id" {
  value = "${aws_security_group.default.id}"
}
