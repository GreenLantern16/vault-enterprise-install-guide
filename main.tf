provider "aws" {
  region = var.aws_region
}

/*
There is a known issue that prevents building the VPC and vault cluster in a single run.
https://github.com/hashicorp/terraform-aws-vault-ent-starter/issues/31
The workaround is to run terraform apply with the below code commented out, 
then to uncomment it and run terraform apply again.
*/

# module "vault-ent" {
#   source               = "/Users/scarolan/git_repos/terraform-aws-vault-ent-starter"
#   friendly_name_prefix = var.friendly_name_prefix
#   vpc_id               = module.vpc.vpc_id
#   secrets_manager_arn   = aws_secretsmanager_secret.tls.arn
#   leader_tls_servername = var.shared_san
#   lb_certificate_arn    = aws_acm_certificate.vault.arn
#   private_subnet_tags   = var.private_subnet_tags
# }