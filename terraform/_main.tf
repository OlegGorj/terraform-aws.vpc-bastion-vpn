
variable instance_type_default {
  default = "t2.micro"
}

###############################################################################
# RESOURCES
###############################################################################
//module "provider" {
//  source                  = "./modules/provider"
//  shared_credentials_file = "${var.cred-file}"
//  aws_region              = "${var.aws_region}"
//  aws_account             = "${var.aws_account}"
//}

provider "aws" {
  region = "${var.aws_region}"
  shared_credentials_file  = "${var.cred-file}"
}

terraform {
  backend "s3" {
    bucket = "aws-terraform-state-bucket"
    key = "vpc-with-bastionbox.tfstate"
    region = "us-west-1"
    profile = "dev"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}

module "networking" {
  source              = "./modules/networking"
  environment         = "${var.environment}"
  region              = "${var.aws_region}"
  availability_zone   = "${var.availability_zone}"
  vpc_cidr            = "${var.vpc_cidr}"
  public_subnet_cidr  = "${var.public-1_subnet_cidr}"
  private_subnet_cidr = "${var.private-1_subnet_cidr}"
  key_name            = "${aws_key_pair.key.key_name}"
}

module "web" {
  source              = "./modules/web"
  environment         = "${var.environment}"
  vpc_id              = "${module.networking.vpc_id}"
  min_size            = 1
  max_size            = 10
  region              = "${var.aws_region}"
  vpc_sg_id           = "${module.networking.default_sg_id}"
  vpc_cidr_block      = "${var.vpc_cidr}"
  availability_zones  = ["${var.availability_zone}"]
  instance_type       = "${var.instance_type_default}"

  public_subnet_id    = "${module.networking.public_subnet_id}"
  private_subnet_id    = "${module.networking.private_subnet_id}"
  subnet_ids          = ["${module.networking.private_subnet_id}"]

  key_name            = "${aws_key_pair.key.key_name}"
  private_key         = "${file("${var.private_key_file}")}"

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
  ami = "${lookup(var.bastion_amis, var.aws_region)}"
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
  ami = "${lookup(var.bastion_amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name            = "${aws_key_pair.key.key_name}"
  admin_user = "admin"
  admin_pw   = "very_secret_"
  private_key = "${file("~/.ssh/dev_key")}"
  vpn_data_vol = "vpn_data_vol"
  vpn_client_name = "ubuntu"
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
