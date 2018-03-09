output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private_subnet_web.id}"
}

output "default_sg_id" {
  value = "${aws_security_group.default.id}"
}

output "bastion_ip" {
  value = "${aws_instance.bastion.private_ip}"
}


output "aws_instance_public_dns" {
  value = "${aws_instance.vpn.public_dns}"
}

output "aws_instance_public_ip" {
  value = "${aws_instance.vpn.public_ip}"
}

output "client_configuration_file" {
  value = "${var.vpn_client_name}.ovpn"
}

output "closing_message" {
  value = "Your VPN is ready! Check out client configuration file to configure your client! Have fun!'"
}
