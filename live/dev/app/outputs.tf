output "bastion_public_ip" { value = module.compute.bastion_public_ip }
output "public_app_public_ip" { value = module.compute.public_app_public_ip }
output "private_app_private_ip" { value = module.compute.private_app_private_ip }
output "db_endpoint" { value = module.database.db_endpoint }
output "alb_dns_name" { value = module.alb.alb_dns_name }
