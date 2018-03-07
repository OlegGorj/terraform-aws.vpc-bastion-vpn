variable "server_ip" {
  default = "10.0.0.2"
}

variable "server_hostname" {
  default = "node01"
}

# Ubuntu reference for hostnamectl: http://manpages.ubuntu.com/manpages/trusty/man1/hostnamectl.1.html
resource "null_resource" "set-hostname" {
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${var.server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.server_hostname}",
      "echo '127.0.0.1 ${var.server_hostname}' | sudo tee -a /etc/hosts",
      "sudo reboot"
    ]
  }
}
