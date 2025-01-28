variable "dynamodb_table_name" {
  type    = string
}


resource "aws_dynamodb_table" "tamako_terraform_lock" {
    name = var.dynamodb_table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    lifecycle {
        prevent_destroy = true
    }

}

output "dynamodb_table_id" {
  value = aws_dynamodb_table.tamako_terraform_lock.id
}

