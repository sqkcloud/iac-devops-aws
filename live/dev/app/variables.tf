variable "aws_region" { type = string default = "ap-northeast-2" }
variable "aws_profile" { type = string default = "default" }
variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string default = "10.10.0.0/16" }
variable "public_subnet_cidr" { type = string default = "10.10.1.0/24" }
variable "public_subnet_b_cidr" { type = string default = "10.10.2.0/24" }
variable "private_app_cidr" { type = string default = "10.10.11.0/24" }
variable "private_data_cidr" { type = string default = "10.10.21.0/24" }
variable "private_data_b_cidr" { type = string default = "10.10.22.0/24" }
variable "az_a" { type = string default = "ap-northeast-2a" }
variable "az_b" { type = string default = "ap-northeast-2c" }
variable "my_ip_cidr" { type = string }
variable "ami_id" { type = string }
variable "public_key_path" { type = string }
variable "instance_type" { type = string default = "t3.micro" }
variable "create_rds" { type = bool default = false }
variable "create_alb" { type = bool default = false }
variable "db_password" { type = string default = "ChangeMe123!" sensitive = true }
variable "tags" { type = map(string) default = {} }
