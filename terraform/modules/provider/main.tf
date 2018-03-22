
###############################################################################
# RESOURCES
###############################################################################
variable shared_credentials_file { default = "" }

variable aws_region { }

variable aws_account { }

provider "aws" {
    version                 = "~> 1.10"
    region                  = "us-west-1"
    profile                 = "${var.aws_account}"
    shared_credentials_file = "${var.shared_credentials_file}"
}
