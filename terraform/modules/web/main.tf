
variable "region" {
  description = "The region to launch the instances"
}

variable "web_amis" {
  default = {
    "us-east-1" = "ami-f652979b"
    "us-east-2" = "ami-fcc19b99"
    "us-west-1" = "ami-16efb076"
  }
}

variable "instance_type" {
  description = "The instance type to launch"
  default     = "t2.micro"
}

variable "public_subnet_id" {
  description = "The id of the public subnet to launch the load balancer"
}
variable "private_subnet_id" {
  description = "The id of the public subnet to launch the load balancer"
}

variable "vpc_sg_id" {
  description = "The default security group from the vpc"
}

variable "vpc_cidr_block" {
  description = "The CIDR block from the VPC"
}

variable "key_name" {
  description = "The keypair to use on the instances"
}

variable "environment" {
  description = "The environment for the instance"
}

variable "vpc_id" {
  description = "The id of the vpc"
}

variable "min_size" {
  description = "Minimum size of the cluster"
}
variable "max_size" {
  description = "Maximum size of the cluster"
}

variable "availability_zones" {
    type    = "list"
    default = []
}
variable "subnet_ids" {
    type    = "list"
    default = []
}
variable "private_key" {
  default = ""
}

###############################################################################
# RESOURCES
###############################################################################
resource "aws_security_group" "web_server_sg" {
  name        = "${var.environment}-web-server-sg"
  description = "Security group for web that allows web traffic from internet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-web-server-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "web_inbound_sg" {
  name        = "${var.environment}-web-inbound-sg"
  description = "Allow HTTP from Anywhere"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-web-inbound-sg"
  }
}

/* Load Balancer */
resource "aws_elb" "web" {
  name            = "${var.environment}-web-lb"
  subnets         = ["${var.public_subnet_id}"]
  security_groups = ["${aws_security_group.web_inbound_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  tags {
    Environment = "${var.environment}"
  }
}

###############################################################################
resource "aws_launch_configuration" "web_config" {
  image_id          = "${lookup(var.web_amis, var.region)}"
  instance_type     = "${var.instance_type}"
  security_groups = [ "${aws_security_group.web_server_sg.id}" ]
  key_name          = "${var.key_name}"
  user_data         = "${data.template_cloudinit_config.webserver_init.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "as_web_group" {
  name = "AS_Web_Group"
  launch_configuration = "${aws_launch_configuration.web_config.id}"
  availability_zones   = ["${var.availability_zones}"]
  load_balancers        = ["${aws_elb.web.name}"]
  health_check_type     = "ELB"
  vpc_zone_identifier   = ["${var.subnet_ids}"]

  min_size              = "${var.min_size}"
  max_size              = "${var.max_size}"

  lifecycle {
    create_before_destroy = true
  }
  tags = [
    {
      key                 = "Name"
      value               = "${var.environment}-webserver-cluster"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    },
  ]

}



data "template_file" "docker_init_script" {
  template = "${file("${path.module}/../../assets/docker/web_init.sh")}"
  vars {
      cidr                = "${var.vpc_cidr_block}"
      domain              = "${aws_elb.web.dns_name}"
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_file" "ngnix_init_script" {
  template = "${file("${path.module}/../../assets/ngnix/ngnix_install.sh")}"
  vars {
      cidr                = "${var.vpc_cidr_block}"
      domain              = "${aws_elb.web.dns_name}"
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_cloudinit_config" "webserver_init" {
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.docker_init_script.rendered}"
  }
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ngnix_init_script.rendered}"
  }
}

//resource "aws_instance" "instance" {
//  ami                    = "${lookup(var.web_amis, var.region)}"
//  instance_type          = "t2.micro"
//  vpc_security_group_ids = [ "${aws_security_group.web_server_sg.id}" ]
//  subnet_id              = "${var.private_subnet_id}"
//  key_name               = "${var.key_name}"
//
//  tags {
//    Name                 = "${var.environment}-ws-experemental-instance"
//  }
//
//  user_data     = "${data.template_cloudinit_config.webserver_init.rendered}"
//
//}

###############################################################################
# OUTPUT
###############################################################################
output "elb.hostname" {
  value = "${aws_elb.web.dns_name}"
}

output "asg.nodes" {
  value = "${aws_autoscaling_group.}"
}
