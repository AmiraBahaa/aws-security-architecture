# AWS Security Architecture

Defense-in-depth security setup for a three-tier application. Covers encryption at rest and in transit, automated threat detection, compliance auditing, and incident response — mapped to the AWS Well-Architected Security Pillar.

## What's included

**Encryption**
- KMS customer-managed keys (CMKs) for S3, RDS, EBS, and SSM — separate key per service for blast radius control
- Secrets Manager with automatic 30-day rotation for DB credentials via a Lambda rotation function

**Threat Detection & Response**
- GuardDuty with S3 logs and malware scan on EBS enabled
- High-severity findings (>= 7) trigger EventBridge → SNS email alert
- CloudTrail multi-region trail with log file integrity validation, stored encrypted in S3

**Compliance**
- Security Hub with CIS AWS Foundations, AWS Foundational Security Best Practices, and PCI DSS standards
- AWS Config recording all resource changes + 5 managed rules: S3 public read prohibited, RDS encryption, root MFA, EBS encryption, IAM password policy

**Edge Protection**
- WAF with AWS managed rule sets: Common (OWASP), SQLi, Known Bad Inputs
- Rate limiting: 2000 requests/5 minutes per IP before block

**IAM**
- Account password policy (16 chars, 90-day rotation, 12-password history)
- Permission boundary applied to all app roles — hard deny on `iam:*` and `organizations:*`
- Least-privilege app role with only the permissions the application actually needs

## Architecture

```
Internet
   |
  WAF  (OWASP rules, SQLi, rate limiting)
   |
  ALB
   |
  EC2 (app role with permission boundary)
   |
  RDS (encrypted with KMS CMK, credentials auto-rotated via Secrets Manager)
  S3  (encrypted with KMS CMK, Config monitoring for public access)

Monitoring layer:
  GuardDuty → EventBridge → SNS
  CloudTrail → S3 (encrypted)
  Config     → S3 + compliance rules
  Security Hub (aggregates all findings)
```

## Setup

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# add your alert_email

terraform init
terraform plan
terraform apply
```

After apply, the GitHub connection for CodeStar (if using with Project 6) needs to be manually confirmed in the AWS Console under Developer Tools → Connections.

## Compliance coverage

| Standard | Status |
|----------|--------|
| CIS AWS Foundations v1.2 | Enabled via Security Hub |
| AWS Foundational Security | Enabled via Security Hub |
| PCI DSS v3.2.1 | Enabled via Security Hub |
