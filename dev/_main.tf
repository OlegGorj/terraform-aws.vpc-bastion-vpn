
provider "aws" {
  region = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}

module "networking" {
  source              = "../modules/networking"
  environment         = "${var.environment}"
  region              = "${var.region}"
  availability_zone   = "${var.availability_zone}"
  vpc_cidr            = "${var.vpc_cidr}"
  public_subnet_cidr  = "${var.public_subnet_cidr}"
  private_subnet_cidr = "${var.private_subnet_cidr}"
  key_name            = "${var.key_name}"
}

module "web" {
  source              = "../modules/web"
  environment         = "${var.environment}"
  vpc_id              = "${module.networking.vpc_id}"
  web_instance_count  = "${var.web_instance_count}"
  region              = "${var.region}"
  public_subnet_id    = "${module.networking.public_subnet_id}"
  private_subnet_id   = "${module.networking.private_subnet_id}"
  vpc_sg_id           = "${module.networking.default_sg_id}"
  vpc_cidr_block      = "${var.vpc_cidr}"
  key_name            = "${var.key_name}"
}
