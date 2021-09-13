# Make sure you have copied your LetsEncrypt fullchain.pem, cert.pem, and prikey.pem
# files into the local directory alongside the terraform files, or this will fail.
locals {
  tls_data = {
    vault_ca   = var.fullchain_b64
    vault_cert = var.cert_b64
    vault_pk   = var.private_key_b64
  }
}

locals {
  secret = jsonencode(local.tls_data)
}

resource "aws_secretsmanager_secret" "tls" {
  name                    = "${var.resource_name_prefix}-tls-secret"
  description             = "contains TLS certs and private keys"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "tls" {
  secret_id     = aws_secretsmanager_secret.tls.id
  secret_string = local.secret
}

resource "aws_acm_certificate" "vault" {
  private_key       = file("./privkey.pem")
  certificate_body  = file("./cert.pem")
  certificate_chain = file("./fullchain.pem")
}