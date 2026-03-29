output "db_endpoint" { value = try(aws_db_instance.this[0].endpoint, null) }
