module "network" {
  source               = "../../../modules/network"
  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  public_subnet_b_cidr = var.public_subnet_b_cidr
  private_app_cidr     = var.private_app_cidr
  private_data_cidr    = var.private_data_cidr
  private_data_b_cidr  = var.private_data_b_cidr
  az_a                 = var.az_a
  az_b                 = var.az_b
  create_alb           = var.create_alb
  create_rds           = var.create_rds
  tags                 = var.tags
}

module "security" {
  source      = "../../../modules/security"
  name_prefix = var.name_prefix
  vpc_id      = module.network.vpc_id
  my_ip_cidr  = var.my_ip_cidr
  create_rds  = var.create_rds
  create_alb  = var.create_alb
}

module "compute" {
  source                = "../../../modules/compute"
  name_prefix           = var.name_prefix
  ami_id                = var.ami_id
  instance_type         = var.instance_type
  public_key_path       = var.public_key_path
  public_subnet_id      = module.network.public_subnet_id
  private_app_subnet_id = module.network.private_app_subnet_id
  bastion_sg_id         = module.security.bastion_sg_id
  public_app_sg_id      = module.security.public_app_sg_id
  private_app_sg_id     = module.security.private_app_sg_id
  public_app_user_data  = <<-EOT
  #!/bin/bash
  yum install -y httpd || dnf install -y httpd || true
  systemctl enable httpd || true
  echo "public app" > /var/www/html/index.html
  systemctl start httpd || true
  EOT
  private_app_user_data = <<-EOT
  #!/bin/bash
  yum install -y httpd || dnf install -y httpd || true
  systemctl enable httpd || true
  echo "private app" > /var/www/html/index.html
  systemctl start httpd || true
  EOT
  tags = var.tags
}

module "database" {
  source                   = "../../../modules/database"
  name_prefix              = var.name_prefix
  create_rds               = var.create_rds
  private_data_subnet_ids  = module.network.private_data_subnet_ids
  db_sg_id                 = module.security.db_sg_id
  db_password              = var.db_password
}

module "alb" {
  source                  = "../../../modules/alb"
  create_alb              = var.create_alb
  name_prefix             = var.name_prefix
  alb_sg_id               = module.security.alb_sg_id
  public_subnet_ids       = compact([module.network.public_subnet_id, module.network.public_subnet_b_id])
  vpc_id                  = module.network.vpc_id
  private_app_instance_id = module.compute.private_app_instance_id
}
