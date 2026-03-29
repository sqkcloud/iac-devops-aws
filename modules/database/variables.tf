variable "name_prefix" { type = string }
variable "create_rds" { type = bool default = false }
variable "private_data_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string default = null }
variable "instance_class" { type = string default = "db.t3.micro" }
variable "allocated_storage" { type = number default = 20 }
variable "db_name" { type = string default = "appdb" }
variable "db_username" { type = string default = "appuser" }
variable "db_password" { type = string sensitive = true }
