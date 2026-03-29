resource "aws_key_pair" "this" {
  key_name   = "${var.name_prefix}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  tags = merge(var.tags, { Name = "${var.name_prefix}-bastion" })
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
}

resource "aws_instance" "public_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_app_sg_id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
  user_data                   = var.public_app_user_data
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-app" })
}

resource "aws_instance" "private_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_app_subnet_id
  vpc_security_group_ids = [var.private_app_sg_id]
  key_name               = aws_key_pair.this.key_name
  user_data              = var.private_app_user_data
  tags = merge(var.tags, { Name = "${var.name_prefix}-private-app" })
}
