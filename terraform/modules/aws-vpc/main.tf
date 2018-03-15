# Create the Cloud Foundry VPC

# Input params
variable "vpc_cidr" {}
variable "vpc_name" {}
variable "r53_zone_name" {}


# RESOURCES
resource "aws_vpc" "main_vpc" {
  cidr_block      = "${var.vpc_cidr}"
  tags {
    Name          = "${var.vpc_name}"
    Terraform     = "true"
  }
}
# Create the Route 53 Zone
resource "aws_route53_zone" "r53_zone" {
  name            = "${var.r53_zone_name}"
  tags {
    Terraform     = "true"
  }
}

# Outputs
output "vpc_id" {
  value = "${aws_vpc.main_vpc.id}"
}

output "r53-zone" {
  value = "${aws_route53_zone.r53_zone.id}"
}
