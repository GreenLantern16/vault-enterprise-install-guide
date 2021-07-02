variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

# VPC variables
variable "azs" {
  description = "availability zones to use in AWS region"
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
}

variable "friendly_name_prefix" {
  description = "Prefix for resource names (e.g. \"prod\")"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19",
  ]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.128.0/20",
    "10.0.144.0/20",
    "10.0.160.0/20",
  ]
}

variable "common_tags" {
  type        = map(string)
  description = "Tags for VPC resources"
  default = {
    Vault = "dev"
  }
}

variable "private_subnet_tags" {
  type        = map(string)
  description = "Tags for private subnets. Be sure to provide these tags to the Vault installation module."
  default = {
    Vault = "deploy"
  }
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

variable "shared_san" {
  type        = string
  description = "This needs to match the TLS hostname you used when you generated the certificate. Example: vault.vaultdemo.net"
}
