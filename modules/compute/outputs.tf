output "bastion_public_ip" { value = aws_eip.bastion.public_ip }
output "public_app_public_ip" { value = aws_instance.public_app.public_ip }
output "private_app_private_ip" { value = aws_instance.private_app.private_ip }

output "private_app_instance_id" { value = aws_instance.private_app.id }
