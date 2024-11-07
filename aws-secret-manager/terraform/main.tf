provider "aws" {
  region = "us-west-2" # Replace with your desired AWS region
}

# Create an AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "webapp_secret" {
  name = "webapp/config"
  description = "Secret for the webapp configuration"
}

# Add key-value pairs to the secret
resource "aws_secretsmanager_secret_version" "webapp_secret_value" {
  secret_id = aws_secretsmanager_secret.webapp_secret.id
  secret_string = jsonencode({
    username = "aws-example-username"
    password = "aws-example-password"
  })
}
