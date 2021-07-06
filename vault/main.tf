provider "aws" {
  region = var.aws_region
}

# This efficient module stands up your Vault cluster. Make sure you have met 
# all the prequisities listed in the README before proceeding.
module "vault-ent" {
  source               = "/Users/scarolan/git_repos/terraform-aws-vault-ent-starter"
  friendly_name_prefix = var.friendly_name_prefix
  vpc_id               = var.vpc_id
  leader_tls_servername = var.shared_san
  private_subnet_tags   = var.private_subnet_tags
  lb_certificate_arn    = aws_acm_certificate.vault.arn
  secrets_manager_arn   = aws_secretsmanager_secret.tls.arn
}