variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "my_ip_cidr" { type = string }
variable "create_rds" { type = bool default = false }
variable "create_alb" { type = bool default = false }
