variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "aws-security-arch"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "alert_email" {
  description = "Email address to receive security alerts"
  type        = string
}

variable "cloudtrail_retention_days" {
  type    = number
  default = 90
}

variable "config_retention_days" {
  type    = number
  default = 30
}
