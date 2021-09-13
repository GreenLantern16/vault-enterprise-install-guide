variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

# TLS and secrets manager variables
variable "kms_key_id" {
  type        = string
  description = "Specifies the ARN or ID of the AWS KMS customer master key (CMK) to be used to encrypt the secret values in the versions stored in this secret. If you don't specify this value, then Secrets Manager defaults to using the AWS account's default CMK (the one named aws/secretsmanager"
  default     = null
}

variable "recovery_window" {
  type        = number
  description = "Specifies the number of days that AWS Secrets Manager waits before it can delete the secret"
  default     = 0
}

variable "tags" {
  type        = map(string)
  description = "Tags for secrets manager secret"
  default = {
    Vault = "tls-data"
  }
}

# Vault variables
variable "vpc_id" {
  type        = string
  description = "VPC id where you want to install Vault. Make sure it meets the requirements outlined in the README doc."
}

variable "shared_san" {
  type        = string
  description = "This needs to match the TLS hostname you used when you generated the certificate. Example: vault.vaultdemo.net"
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Tags for private subnets. Make sure your subnets are tagged with these settings:"
  default = {
    Vault = "deploy"
  }
}

variable "license_filepath" {
  description = "Local path to your Vault license `.hclic` file."
  default     = "vault.hclic"
}

variable "resource_name_prefix" {
  description = "A human-resource prefix for your resources in AWS."
  default     = "vault"
}