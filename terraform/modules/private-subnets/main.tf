
###############################################################################
# VARIABLES
###############################################################################

variable "name" { default = "private" }
variable "cidrs" {}
variable "azs" {}
variable "vpc_id" {}
variable "nat_instance_ids" {}

###############################################################################
# RESOURCES
###############################################################################

resource "aws_subnet" "private" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(split(",", var.cidrs), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(split(",", var.cidrs))}"

  tags { Name = "${var.name}.${element(split(",", var.azs), count.index)}" }
}

resource "aws_route_table" "private" {
  vpc_id = "${var.vpc_id}"
  count  = "${length(split(",", var.cidrs))}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${element(split(",", var.nat_instance_ids), count.index)}"
  }

  tags { Name = "${var.name}.${element(split(",", var.azs), count.index)}" }
}

resource "aws_route_table_association" "private" {
  count          = "${length(split(",", var.cidrs))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

# TODO: Determine if there will be an ACL per subnet or 1 for all
/*
resource "aws_network_acl" "private" {
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.private.*.id}"]
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags { Name = "${var.name}" }
}
*/

###############################################################################
# OUTPUT
###############################################################################

output "subnet_ids" { value = "${join(",", aws_subnet.private.*.id)}" }
