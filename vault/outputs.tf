output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = var.shared_san
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault load balancer"
  value       = module.vault-ent.vault_lb_dns_name
}

