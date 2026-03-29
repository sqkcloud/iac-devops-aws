output "bastion_sg_id" { value = aws_security_group.bastion.id }
output "public_app_sg_id" { value = aws_security_group.public_app.id }
output "private_app_sg_id" { value = aws_security_group.private_app.id }
output "db_sg_id" { value = try(aws_security_group.db[0].id, null) }
output "alb_sg_id" { value = try(aws_security_group.alb[0].id, null) }
