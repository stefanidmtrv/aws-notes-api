resource "aws_apigatewayv2_api" "notes_api" {
  name          = "notes-api"
  protocol_type = "HTTP"
}