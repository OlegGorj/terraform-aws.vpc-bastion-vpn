output "elb_hostname" {
  value = "${module.web.elb.hostname}"
}

# outputs from networking modules
output "aws_instance_public_dns" {
  value = "${module.networking.aws_instance_public_dns}"
}

output "aws_instance_public_ip" {
  value = "${module.networking.aws_instance_public_ip}"
}

output "client_configuration_file" {
  value = "${module.networking.client_configuration_file}"
}

output "closing_message" {
  value = "${module.networking.closing_message}"
}
