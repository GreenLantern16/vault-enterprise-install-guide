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

variable "resource_name_prefix" {
  description = "A human-resource prefix for your resources in AWS."
  default     = "vault"
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