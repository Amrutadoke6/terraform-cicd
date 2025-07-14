output "alb_dns_name" {
  value = aws_lb.internal_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.sql.endpoint
}

