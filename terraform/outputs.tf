output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.main.arn
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "kms_s3_key_arn" {
  value = aws_kms_key.s3.arn
}

output "kms_rds_key_arn" {
  value = aws_kms_key.rds.arn
}

output "db_secret_arn" {
  value     = aws_secretsmanager_secret.db_credentials.arn
  sensitive = true
}

output "permission_boundary_arn" {
  value = aws_iam_policy.permission_boundary.arn
}
