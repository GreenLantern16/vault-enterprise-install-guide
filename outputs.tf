output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = var.shared_san
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault load balancer"
  value       = module.vault-ent.vault_lb_dns_name
}

# output "vault_lb_zone_id" {
#   description = "Zone ID of Vault load balancer"
#   value       = module.vault-ent.vault_lb_zone_id
# }

# output "vault_lb_arn" {
#   description = "ARN of Vault load balancer"
#   value       = module.vault-ent.vault_lb_arn
# }

# output "vault_target_group_arn" {
#   description = "Target group ARN to register Vault nodes with"
#   value       = module.vault-ent.vault_target_group_arn
# }