# AWS Informatation
aws_account       = "dev"
aws_region        = "us-west-1"

# aws_vpc Module
vpc_name          = "vpc_dev"
vpc_cidr          = "10.233.0.0/16"
r53_zone_name     = "poc.cloud.io"

# public-subnets module
public-1_create = true
# private-subnets module
private-1_create = true
private-2_create = true

public-1_subnet_cidr = "10.233.1.0/28"
private-1_subnet_cidr = "10.233.2.0/28"
private-2_subnet_cidr = "10.233.3.0/28"

private_key_file         = "~/.ssh/dev_key"
