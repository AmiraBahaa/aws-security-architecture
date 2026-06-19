resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "/${var.project_name}/${var.environment}/db-credentials"
  kms_key_id              = aws_kms_key.rds.arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_db_secret.arn

  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_iam_role" "rotation_lambda" {
  name = "${var.project_name}-secret-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_basic" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "rotation_lambda_secrets" {
  name = "${var.project_name}-rotation-secrets"
  role = aws_iam_role.rotation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue", "secretsmanager:PutSecretValue", "secretsmanager:UpdateSecretVersionStage"]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.rds.arn
      }
    ]
  })
}

data "archive_file" "rotation_lambda" {
  type        = "zip"
  output_path = "${path.module}/rotation_lambda.zip"

  source {
    content  = <<-EOF
      import boto3
      import json

      def lambda_handler(event, context):
          arn = event['SecretId']
          token = event['ClientRequestToken']
          step = event['Step']

          client = boto3.client('secretsmanager')

          if step == 'createSecret':
              current = client.get_secret_value(SecretId=arn, VersionStage='AWSCURRENT')
              client.put_secret_value(SecretId=arn, ClientRequestToken=token, SecretString=current['SecretString'], VersionStages=['AWSPENDING'])
          elif step == 'finishSecret':
              client.update_secret_version_stage(SecretId=arn, VersionStage='AWSCURRENT', MoveToVersionId=token, RemoveFromVersionId=client.describe_secret(SecretId=arn)['VersionIdsToStages'].get('AWSCURRENT', [None])[0])
    EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "rotate_db_secret" {
  filename         = data.archive_file.rotation_lambda.output_path
  function_name    = "${var.project_name}-rotate-db-secret"
  role             = aws_iam_role.rotation_lambda.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }
}

resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_db_secret.function_name
  principal     = "secretsmanager.amazonaws.com"
}
