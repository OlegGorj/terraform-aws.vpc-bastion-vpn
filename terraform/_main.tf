
###############################################################################
# RESOURCES
###############################################################################
provider "aws" {
  region = "${var.aws_region}"
  shared_credentials_file  = "${var.cred-file}"
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
  web_instance_count  = "${var.web_instance_count}"
  region              = "${var.aws_region}"
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
