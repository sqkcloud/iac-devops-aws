output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_id" { value = aws_subnet.public_a.id }
output "public_subnet_b_id" { value = try(aws_subnet.public_b[0].id, null) }
output "private_app_subnet_id" { value = aws_subnet.private_app.id }
output "private_data_subnet_ids" { value = compact([aws_subnet.private_data_a.id, try(aws_subnet.private_data_b[0].id, null)]) }
