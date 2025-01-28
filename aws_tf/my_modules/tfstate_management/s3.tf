variable "bucket_name" {
  type    = string
}


resource "aws_s3_bucket" "tf_state_bucket" {
    bucket = var.bucket_name
    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "tf_state_bucket_versioning" {
    bucket = aws_s3_bucket.tf_state_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_bucket_server_side_encryption_configuration" {
    bucket = aws_s3_bucket.tf_state_bucket.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "tf_state_bucket_public_access_block" {
    bucket = aws_s3_bucket.tf_state_bucket.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

output "tf_state_bucket_id" {
  value = aws_s3_bucket.tf_state_bucket.id
}

output "tf_state_bucket_arn" {
  value = aws_s3_bucket.tf_state_bucket.arn
}

