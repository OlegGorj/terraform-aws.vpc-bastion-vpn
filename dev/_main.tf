
provider "aws" {
  region = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}
