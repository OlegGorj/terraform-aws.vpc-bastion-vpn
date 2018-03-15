provider "aws" {
    version = "~> 1.10"
    region  = "${var.aws_region}"
    profile = "${var.aws_account}"
}
