variable "name_prefix" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string default = "t3.micro" }
variable "public_key_path" { type = string }
variable "public_subnet_id" { type = string }
variable "private_app_subnet_id" { type = string }
variable "bastion_sg_id" { type = string }
variable "public_app_sg_id" { type = string }
variable "private_app_sg_id" { type = string }
variable "public_app_user_data" { type = string default = "" }
variable "private_app_user_data" { type = string default = "" }
variable "tags" { type = map(string) default = {} }
