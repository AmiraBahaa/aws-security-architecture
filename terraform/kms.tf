data "aws_iam_policy_document" "kms_default" {
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "s3" {
  description             = "CMK for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_default.json
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}/s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "rds" {
  description             = "CMK for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_default.json
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}/rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "ebs" {
  description             = "CMK for EBS volume encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_default.json
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}/ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

resource "aws_kms_key" "ssm" {
  description             = "CMK for SSM Parameter Store"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_default.json
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.project_name}/ssm"
  target_key_id = aws_kms_key.ssm.key_id
}
