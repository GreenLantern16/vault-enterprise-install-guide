provider "aws" {
  region = var.aws_region
}

module "vault-ent" {
  # Change this source to wherever you cloned the terraform-aws-vault-ent-starter module.
  # This module is not in the public registry yet.
  source               = "/Users/scarolan/git_repos/terraform-aws-vault-ent-starter"
  friendly_name_prefix = var.friendly_name_prefix
  vpc_id               = module.vpc.vpc_id
  secrets_manager_arn   = aws_secretsmanager_secret.tls.arn
  leader_tls_servername = var.shared_san
  lb_certificate_arn    = aws_acm_certificate.vault.arn
  private_subnet_tags   = var.private_subnet_tags
}