resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Bastion SG"
  vpc_id      = var.vpc_id
  ingress { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.my_ip_cidr] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "public_app" {
  name   = "${var.name_prefix}-public-app-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "private_app" {
  name   = "${var.name_prefix}-private-app-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 22 to_port = 22 protocol = "tcp" security_groups = [aws_security_group.bastion.id] }
  ingress { from_port = 80 to_port = 80 protocol = "tcp" security_groups = compact([aws_security_group.public_app.id, try(aws_security_group.alb[0].id, "")]) }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "db" {
  count  = var.create_rds ? 1 : 0
  name   = "${var.name_prefix}-db-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 5432 to_port = 5432 protocol = "tcp" security_groups = [aws_security_group.private_app.id] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "alb" {
  count  = var.create_alb ? 1 : 0
  name   = "${var.name_prefix}-alb-sg"
  vpc_id = var.vpc_id
  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}
