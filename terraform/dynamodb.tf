resource "aws_dynamodb_table" "notes" {
  name         = "notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "noteId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "noteId"
    type = "S"
  }
}