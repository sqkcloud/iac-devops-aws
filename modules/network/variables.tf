variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "public_subnet_b_cidr" { type = string default = "10.10.2.0/24" }
variable "private_app_cidr" { type = string }
variable "private_data_cidr" { type = string }
variable "private_data_b_cidr" { type = string default = "10.10.22.0/24" }
variable "az_a" { type = string }
variable "az_b" { type = string }
variable "create_alb" { type = bool default = false }
variable "create_rds" { type = bool default = false }
variable "tags" { type = map(string) default = {} }
