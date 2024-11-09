# Configure the AWS provider
provider "aws" {
  region = "eu-central-1" # Replace with your desired AWS region
}

# Create an AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "webapp_secret" {
  name        = "webapp/config"
  description = "Secret for the webapp configuration"
}

# Add key-value pairs to the secret
resource "aws_secretsmanager_secret_version" "webapp_secret_value" {
  secret_id     = aws_secretsmanager_secret.webapp_secret.id
  secret_string = jsonencode({
    username = "aws-example-username"
    password = "aws-example-password"
  })
}

# Create an IAM user for ESO to access the secret
resource "aws_iam_user" "eso_user" {
  name = "ESOUser"
}

# Define a policy to grant access to the AWS Secret
resource "aws_iam_policy" "eso_secrets_access_policy" {
  name   = "ESOSecretsAccessPolicy"
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource: aws_secretsmanager_secret.webapp_secret.arn
      }
    ]
  })
}

# Attach the policy to the IAM user
resource "aws_iam_user_policy_attachment" "eso_user_policy_attachment" {
  user       = aws_iam_user.eso_user.name
  policy_arn = aws_iam_policy.eso_secrets_access_policy.arn
}

# Generate access keys for the ESO user
resource "aws_iam_access_key" "eso_access_key" {
  user = aws_iam_user.eso_user.name
}

# Output the access keys securely
output "eso_access_key_id" {
  value     = aws_iam_access_key.eso_access_key.id
  sensitive = true
}

output "eso_secret_access_key" {
  value     = aws_iam_access_key.eso_access_key.secret
  sensitive = true
}