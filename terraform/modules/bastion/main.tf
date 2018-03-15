###############################################################################
# VARIABLES
###############################################################################
variable "environment" {
  default = "dev"
}
variable "vpn_port" {
  default = 1194
}
variable "vpn_cidr" {
  default = "0.0.0.0/0"
}
variable "ssh_port" {
  default = 22
}
variable "ssh_cidr" {
  default = "0.0.0.0/0"
}
variable "icmp_port_from" {
  default = 8
}
variable "icmp_port_to" {
  default = 0
}
variable "icmp_cidr" {
  default = "0.0.0.0/0"
}
variable "ui_port" {
  default = 443
}
variable "ui_cidr" {
  default = "0.0.0.0/0"
}
variable "ami" {
  description = "Base AMI to launch the openvpn with"
}
variable "instance_type" {
  description = "Type of ec2 instance used for openvpn node"
  default     = "t2.micro"
}
variable "key_name" {
  description = "The public key for the bastion host"
}
variable "subnet_id" {
}
variable "private_key" {
  default = ""
}
variable "vpc_id" {
  default = ""
}
variable "vpc_cidr" {
  default = ""
}
variable "connection_user" {
  default = "ubuntu"
}

###############################################################################
# RESOURCES
###############################################################################
resource "aws_security_group" "bastion_sg" {


  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-bastion-host"
  description = "Allow SSH to bastion host"

  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.icmp_port_from}"
    to_port     = "${var.icmp_port_to}"
    protocol    = "icmp"
    cidr_blocks = ["${var.icmp_cidr}"]
  }

  tags {
    Name        = "${var.environment}-bastion-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "bastion" {

//  depends_on = ["module.networking"]
  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
  subnet_id                   = "${var.subnet_id}"
//  associate_public_ip_address = true
  monitoring                  = true

  tags {
    Name        = "${var.environment}-bastion"
    Environment = "${var.environment}"
  }

  connection {
      user = "${var.connection_user}"
      private_key = "${var.private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo touch /var/log/bastion.tf.log",
    ]
  }
}
###############################################################################
# OUTPUT
###############################################################################

output "bastion_ip" {
  value = "${aws_instance.bastion.private_ip}"
}
