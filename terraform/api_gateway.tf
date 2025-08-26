locals {
  api_name           = "notes-api"
  api_log_group_name = "/aws/apigateway/${local.api_name}"
  api_allow_methods  = ["GET", "POST", "PUT", "DELETE"]
}

###################
# API
###################
resource "aws_apigatewayv2_api" "notes_api" {
  name          = local.api_name
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "api_log_group" {
  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = 14

}
resource "aws_apigatewayv2_stage" "notes_api_stage" {
  api_id      = aws_apigatewayv2_api.notes_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_log_group.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

###################
# API Integration
###################
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.notes_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.notes_lambda.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_proxy_route" {
  count     = length(local.api_allow_methods)
  api_id    = aws_apigatewayv2_api.notes_api.id
  route_key = "${local.api_allow_methods[count.index]} /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notes_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.notes_api.execution_arn}/*/*"
}
