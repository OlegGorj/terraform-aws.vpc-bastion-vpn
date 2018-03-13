

variable "region" {
  description = "Region that the instances will be created"
  default = "us-west-1"
}
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

###############################################################################
# RESOURCES
###############################################################################
provider "aws" {
  region = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}

module "networking" {
  source              = "./modules/networking"
  environment         = "${var.environment}"
  region              = "${var.region}"
  availability_zone   = "${var.availability_zone}"
  vpc_cidr            = "${var.vpc_cidr}"
  public_subnet_cidr  = "${var.public_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  key_name            = "${aws_key_pair.key.key_name}"
}

module "web" {
  source              = "./modules/web"
  environment         = "${var.environment}"
  vpc_id              = "${module.networking.vpc_id}"
  web_instance_count  = "${var.web_instance_count}"
  region              = "${var.region}"
  public_subnet_id    = "${module.networking.public_subnet_id}"
  private_subnet_id   = "${module.networking.private_subnet_id}"
  vpc_sg_id           = "${module.networking.default_sg_id}"
  vpc_cidr_block      = "${var.vpc_cidr}"
  key_name            = "${aws_key_pair.key.key_name}"
}

module "bastion" {
  source              = "./modules/bastion"
  environment         = "${var.environment}"
  vpc_cidr            = "${var.vpc_cidr}"
  vpc_id = "${module.networking.vpc_id}"
  subnet_id  = "${module.networking.public_subnet_id}"
  ssh_port = 22
  icmp_port_from = 8
  icmp_port_to = 0
  ami = "${lookup(var.bastion_amis, var.region)}"
  instance_type = "t2.micro"
  key_name            = "${aws_key_pair.key.key_name}"
  private_key = "${file("~/.ssh/dev_key")}"
  connection_user = "ubuntu"
}

module "openvpn" {
  source              = "./modules/openvpn"
  environment         = "${var.environment}"
  vpc_cidr            = "${var.vpc_cidr}"
  vpc_id = "${module.networking.vpc_id}"
  subnet_id  = "${module.networking.public_subnet_id}"
  vpn_port = 1194
  ssh_port = 22
  icmp_port_from = 8
  icmp_port_to = 0
  ui_port = "443"
  ami = "${lookup(var.bastion_amis, var.region)}"
  instance_type = "t2.micro"
  key_name            = "${aws_key_pair.key.key_name}"
  admin_user = ""
  admin_pw   = ""
  private_key = "${file("~/.ssh/dev_key")}"
  vpn_data_vol = "vpn_data_vol"
  vpn_client_name = "docker"
  ssh_remote_user = "ubuntu"
}

###############################################################################
# OUTPUT
###############################################################################
output "elb_hostname" {
  value = "${module.web.elb.hostname}"
}

output "aws_vpn_instance_public_dns" {
  value = "${module.openvpn.aws_vpn_instance_public_dns}"
}

output "aws_vpn_instance_public_ip" {
  value = "${module.openvpn.aws_vpn_instance_public_ip}"
}

output "client_configuration_file" {
  value = "${module.openvpn.client_configuration_file}"
}

output "closing_message" {
  value = "${module.openvpn.closing_message}"
}
