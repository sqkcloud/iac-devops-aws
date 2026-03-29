variable "aws_region" { type = string default = "ap-northeast-2" }
variable "project_name" { type = string default = "tf-ops" }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "github_oidc_thumbprint" { type = string default = "6938fd4d98bab03faadb97b34396831e3780aea1" }
variable "tf_state_bucket_dev" { type = string }
variable "tf_state_bucket_stage" { type = string }
variable "tf_state_bucket_prod" { type = string }
variable "tf_lock_table_dev_arn" { type = string default = "" }
variable "tf_lock_table_stage_arn" { type = string default = "" }
variable "tf_lock_table_prod_arn" { type = string default = "" }
variable "tags" { type = map(string) default = {} }
