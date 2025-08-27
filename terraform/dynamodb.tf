resource "aws_dynamodb_table" "notes_table" {
  name         = "notes_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

}