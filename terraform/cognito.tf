resource "aws_cognito_user_pool" "users" {
  name = "notes-users"
}

resource "aws_cognito_user_pool_client" "client" {
  name            = "notes-client"
  user_pool_id    = aws_cognito_user_pool.users.id
  generate_secret = false
}

resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  name             = "notes"
  api_id           = aws_apigatewayv2_api.notes_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = aws_cognito_user_pool.users.endpoint
  }
}