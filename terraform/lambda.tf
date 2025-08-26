locals {
  app_name                = "notes-app"
  function_name           = "notes-lambda"
  runtime                 = "python3.12"
  integration_role_name   = "${local.app_name}-api-integration-role"
  integration_policy_name = "${local.app_name}-api-integration-policy"
}

###################
# Lambda Function
###################
resource "aws_lambda_function" "notes_lambda" {
  function_name = local.function_name
  description   = "Lambda function for Notes app"
  handler       = "app.lambda_handler"
  runtime       = local.runtime
  role          = aws_iam_role.lambda_exec.arn
  filename     = "lambda-notes.zip"
}

###################
# IAM Role for Lambda
###################
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "additional_policy" {
  name = "lambda_additional_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.notes.arn
      },
    ]
  })
}

####################
# API Integration Permission
####################

resource "aws_iam_role" "integration_role" {
  name = local.integration_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_role_policy" "integration_policy" {
  name = local.integration_policy_name
  role = aws_iam_role.integration_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.notes_lambda.arn
      }
    ]
  })
}
