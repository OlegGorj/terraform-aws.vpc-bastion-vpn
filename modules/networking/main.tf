resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

/* Internet gateway for the PUBLIC subnet */
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}



/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc = true
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_subnet_cidr}"
  availability_zone       = "${var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name        = "${var.environment}-public-subnet"
    Environment = "${var.environment}"
  }
}

/* Private subnet WEB */
resource "aws_subnet" "private_subnet_web" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.private_subnet_cidr}"
  map_public_ip_on_launch = false
  availability_zone       = "${var.availability_zone}"

  tags {
    Name        = "${var.environment}-private-subnet"
    Environment = "${var.environment}"
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id       = "${aws_subnet.private_subnet_web.id}"
  route_table_id  = "${aws_route_table.private.id}"
}

/* Default security group */
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags {
    Environment = "${var.environment}"
  }
}

/* Bastion security group */
resource "aws_security_group" "bastion_sg" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name        = "${var.environment}-bastion-host"
  description = "Allow SSH to bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

//  ingress {
//    from_port   = 8
//    to_port     = 0
//    protocol    = "icmp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }

  tags {
    Name        = "${var.environment}-bastion-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_instance" "bastion" {
  ami                         = "${lookup(var.bastion_ami, var.region)}"
  instance_type               = "${var.bastion_instance_type}"
  key_name                    = "${var.key_name}"
  monitoring                  = true
  vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
  subnet_id                   = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true

  tags {
    Name        = "${var.environment}-bastion"
    Environment = "${var.environment}"
  }
}


###############################################################################
# VARIABLES
###############################################################################
variable "private_key" {
  default = ""
}
variable "ssh_user" {
  default = "openvpnas"
}
variable "ssh_port" {
  default = 22
}
variable "ssh_cidr" {
  default = "0.0.0.0/0"
}
variable "https_port" {
  default = 443
}
variable "https_cidr" {
  default = "0.0.0.0/0"
}
variable "tcp_port" {
  default = 943
}
variable "tcp_cidr" {
  default = "0.0.0.0/0"
}
variable "udp_port" {
  default = 1194
}
variable "udp_cidr" {
  default = "0.0.0.0/0"
}

variable "vpn_port" {
  default = 1194
}
variable "ssh_remote_user" {
  default = "docker"
}
variable "vpn_data_vol" {
  default = "openvpn-data-default"
}
variable "vpn_client_name" {
  default = "personal-vpn-client"
}
# Bastion
variable "openvpn_instance_type" {
  description = "Type of ec2 instance used for openvpn node"
  default     = "t2.micro"
}

###############################################################################
# RESOURCES
###############################################################################
resource "aws_key_pair" "openvpn" {
  key_name   = "terraform-deployer-openvpn-key"
  public_key = "${file("~/.ssh/dev_key.pub")}"    # aws_key_pair.key.public_key
}

###############################################################################

resource "aws_security_group" "openvpn_sg" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name = "terraform-openvpn-security-group"
  ingress {
    from_port   = "${var.vpn_port}"
    to_port     = "${var.vpn_port}"
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vpn" {

  instance_type = "${var.openvpn_instance_type}"
  ami           = "ami-16efb076"
  key_name = "terraform-deployer-openvpn-key"
  subnet_id = "${aws_subnet.public_subnet.id}"

  vpc_security_group_ids = [ "${aws_security_group.openvpn_sg.id}" ]

  connection {
    user = "${var.ssh_remote_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "docker volume create --name ${var.vpn_data_vol}",
      "docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://${aws_instance.vpn.public_dns}",
      "yes 'yes' | docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm -i kylemanna/openvpn ovpn_initpki nopass",
      "docker run -v ${var.vpn_data_vol}:/etc/openvpn -d -p ${var.vpn_port}:${var.vpn_port}/udp --cap-add=NET_ADMIN kylemanna/openvpn",
      "docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full ${var.vpn_client_name} nopass",
      "docker run -v ${var.vpn_data_vol}:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient ${var.vpn_client_name} > ~/${var.vpn_client_name}.ovpn",
    ]
  }

  provisioner "local-exec" {
    command    = "ssh-keyscan -T 120 ${aws_instance.vpn.public_ip} >> ~/.ssh/known_hosts"
  }

  provisioner "local-exec" {
    command    = "scp ${var.ssh_remote_user}@${aws_instance.vpn.public_ip}:~/${var.vpn_client_name}.ovpn ."
  }

  tags {
    Name = "${var.environment}-terraform-openvpn"
  }
}


#resource "null_resource" "provision_openvpn" {
#  triggers {
#    subdomain_id = "${aws_route53_record.vpn.id}"
#  }
#
#  connection {
#    type        = "ssh"
#    host        = "${aws_instance.openvpn.public_ip}"
#    user        = "${var.ssh_user}"
#    port        = "${var.ssh_port}"
#    private_key = "${file("~/.ssh/dev_key")}"
#    agent       = false
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "sudo apt-get install -y curl vim libltdl7 python3 python3-pip python software-properties-common unattended-upgrades",
#      "sudo add-apt-repository -y ppa:certbot/certbot",
#      "sudo apt-get -y update",
#      "sudo apt-get -y install python-certbot certbot",
#      "sudo service openvpnas stop",
#      "sudo certbot certonly --standalone --non-interactive --agree-tos --email oleggorj@hotmail.com --domains ${var.subdomain_name} --pre-hook 'service openvpnas stop' --post-hook 'service openvpnas start'",
#      "sudo ln -s -f /etc/letsencrypt/live/${var.subdomain_name}/cert.pem /usr/local/openvpn_as/etc/web-ssl/server.crt",
#      "sudo ln -s -f /etc/letsencrypt/live/${var.subdomain_name}/privkey.pem /usr/local/openvpn_as/etc/web-ssl/server.key",
#      "sudo service openvpnas start",
#    ]
#  }
#}
