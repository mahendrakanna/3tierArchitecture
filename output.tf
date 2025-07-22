# outputs.tf

output "web_server_public_ips" {
  description = "Public IP addresses of the web servers."
  value       = [for instance in aws_instance.web_server : instance.public_ip]
}

output "app_server_private_ips" {
  description = "Private IP addresses of the application servers."
  value       = [for instance in aws_instance.app_server : instance.private_ip]
}

output "database_endpoint" {
  description = "Endpoint address of the RDS database."
  value       = aws_db_instance.main_db.address
}

output "database_port" {
  description = "Port of the RDS database."
  value       = aws_db_instance.main_db.port
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.three_tier_vpc.id
}
