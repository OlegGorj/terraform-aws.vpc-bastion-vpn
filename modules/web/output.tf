output "elb.hostname" {
  value = "${aws_elb.web.dns_name}"
}

output "web_private_ip" {
  value = ["${aws_instance.web.*.private_ip}"]
}
