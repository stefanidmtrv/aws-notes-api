resource "aws_cognito_user_pool" "users" {
  name = "notes-users"
}

resource "aws_cognito_user_pool_client" "client" {
  name            = "notes-client"
  user_pool_id    = aws_cognito_user_pool.users.id
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  name             = "notes"
  api_id           = aws_apigatewayv2_api.notes_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.eu-north-1.amazonaws.com/${aws_cognito_user_pool.users.id}"
  }
}