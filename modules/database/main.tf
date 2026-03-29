resource "aws_db_subnet_group" "this" {
  count      = var.create_rds ? 1 : 0
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids
}

resource "aws_db_instance" "this" {
  count                     = var.create_rds ? 1 : 0
  identifier                = "${var.name_prefix}-postgres"
  engine                    = "postgres"
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  skip_final_snapshot       = true
  publicly_accessible       = false
  vpc_security_group_ids    = [var.db_sg_id]
  db_subnet_group_name      = aws_db_subnet_group.this[0].name
  backup_retention_period   = 0
  deletion_protection       = false
}
