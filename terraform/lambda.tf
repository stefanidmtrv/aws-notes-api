locals {
  app_name                = "notes-app"
  function_name           = "notes-lambda"
  runtime                 = "python3.12"
  integration_role_name   = "${local.app_name}-api-integration-role"
  integration_policy_name = "${local.app_name}-api-integration-policy"
  builtin_layers_arn      = ["arn:aws:lambda:eu-north-1:017000801446:layer:AWSLambdaPowertoolsPythonV3-python312-x86_64:19"]
}

###################
# Lambda Function
###################
resource "aws_lambda_function" "notes_lambda" {
  function_name    = local.function_name
  description      = "Lambda function for Notes app"
  handler          = "app.lambda_handler"
  runtime          = local.runtime
  role             = aws_iam_role.lambda_exec.arn
  filename         = "lambda-notes.zip"
  source_code_hash = filebase64sha256("lambda-notes.zip")
  depends_on       = [aws_cloudwatch_log_group.lambda_log_group]

  layers = local.builtin_layers_arn

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
        Resource = aws_dynamodb_table.notes_table.arn
      },
    ]
  })
}

resource "aws_iam_policy" "function_logging_policy" {
  name = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.lambda_exec.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
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
