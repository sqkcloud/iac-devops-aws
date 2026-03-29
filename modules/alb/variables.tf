variable "create_alb" { type = bool default = false }
variable "name_prefix" { type = string }
variable "alb_sg_id" { type = string default = null }
variable "public_subnet_ids" { type = list(string) default = [] }
variable "vpc_id" { type = string }
variable "private_app_instance_id" { type = string }
