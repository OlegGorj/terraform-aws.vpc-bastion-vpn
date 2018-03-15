
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
variable "admin_user" {
  default = ""
}
variable "admin_pw" {
  default = ""
}
variable "private_key" {
  default = ""
}
variable "vpn_data_vol" {
}
variable "vpn_client_name" {
  default = ""
}
variable "vpc_id" {
  default = ""
}
variable "vpc_cidr" {
  default = ""
}
variable "ssh_remote_user" {
  default = "ubuntu"
}

###############################################################################
# RESOURCES
###############################################################################

resource "aws_security_group" "openvpn_sg" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-openvpn-host"

  ingress {
    from_port   = "${var.vpn_port}"
    to_port     = "${var.vpn_port}"
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-openvpn-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "vpn" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${var.subnet_id}"
  vpc_security_group_ids = [ "${aws_security_group.openvpn_sg.id}" ]
  monitoring                  = true
  associate_public_ip_address = true
  user_data = <<USERDATA
admin_user="${var.admin_user}"
admin_pw="${var.admin_pw}"
USERDATA

  tags {
    Name        = "${var.environment}-openvpn"
    Environment = "${var.environment}"
  }

  connection {
      user = "ubuntu"
      private_key = "${var.private_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo touch /var/log/tf.remote.log",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get update",
      "apt-cache policy docker-ce",
      "sudo apt-get install -y docker-ce",
      "sudo docker volume create --name ${var.vpn_data_vol}",
      "sudo docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://${aws_instance.vpn.public_dns}",
      "yes 'yes' | sudo docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm -i kylemanna/openvpn ovpn_initpki nopass",
      "sudo docker run -v ${var.vpn_data_vol}:/etc/openvpn -d -p ${var.vpn_port}:${var.vpn_port}/udp --cap-add=NET_ADMIN kylemanna/openvpn",
      "sudo docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full ${var.vpn_client_name} nopass",
      "sudo docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient ${var.vpn_client_name} > ~/${var.vpn_client_name}.ovpn",
    ]
  }

  provisioner "local-exec" {
    command    = "ssh-keyscan -T 120 ${aws_instance.vpn.public_dns} >> ~/.ssh/known_hosts"
  }

  provisioner "local-exec" {
    command    = "scp ${var.ssh_remote_user}@${aws_instance.vpn.public_dns}:~/${var.vpn_client_name}.ovpn ."
  }

}

###############################################################################
# OUTPUT
###############################################################################

output "aws_vpn_instance_public_dns" {
  value = "${aws_instance.vpn.public_dns}"
}

output "aws_vpn_instance_public_ip" {
  value = "${aws_instance.vpn.public_ip}"
}

output "client_configuration_file" {
  value = "${var.vpn_client_name}.ovpn"
}

output "closing_message" {
  value = "Your VPN is ready! Check out client configuration file to configure your client! Have fun!'"
}
