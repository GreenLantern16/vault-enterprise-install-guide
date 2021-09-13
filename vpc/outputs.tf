output "private_subnet_tags" {
  description = "Tags for private subnets to identify them for Vault node deployment."
  value       = var.private_subnet_tags
}

output "vpc_id" {
  description = "VPC id. Use this as the vpc_id variable in your Vault deployment configuration."
  value       = module.vpc.vpc_id
}