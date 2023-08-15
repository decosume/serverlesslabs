#PCC API For Ticketing System
#October 2022
#Tech9 

provider "aws" {
  region =var.aws_region
}

# Adding S3 buckets for tickets and transactions
resource "aws_s3_bucket" "pccdailytransactionreport" {
  bucket        = var.bucket_name_transactions
  acl           = "private"

  versioning {
    enabled    = "true"
 }
}

# Adding Lambda function for transactions
resource "aws_lambda_function" "pcc_dailytransactionFn" {
  architectures = ["x86_64"]

  ephemeral_storage {
    size = "1024"
  }

  function_name                  = var.transactions_name_function
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = "512"
  package_type                   = "Zip"
  reserved_concurrent_executions = "-1"
  role                           = "${aws_iam_role.pcc_dailytransactionFn-role-v0fpf6ka.arn}"  
  runtime                        = "python3.9"
  source_code_hash               = "9HQJd9/HuwpLTELojtyUKy+BFksKi7crG6uN8KD4PB4="
  timeout                        = "300"
  filename                       = "pcc_dailytransactionFn.zip"

  environment {
    variables = {
      transactions_dynamodb_table = var.transactions_name_table
    }
  }

}

# Adding DynamoDB table for transactions
resource "aws_dynamodb_table" "pccdailytransactionreportt" {
  attribute {
    name = "Order ID"
    type = "S"
  }

  attribute {
    name = "TransactionID"
    type = "S"
  }

  billing_mode = "PROVISIONED"
  hash_key     = "TransactionID"
  name         = var.transactions_name_table

  point_in_time_recovery {
    enabled = "false"
  }

  range_key      = "Order ID"
  stream_enabled = "false"
  write_capacity = 1
  read_capacity  = 1

  lifecycle{
    ignore_changes = [write_capacity, read_capacity]
  }
}

# Adding resource and policy for Read Autoscaling
resource "aws_appautoscaling_target" "dynamodb_table_pccdailytransactionreportt_read" {
  max_capacity       = 100
  min_capacity       = 10
  resource_id        = "table/${aws_dynamodb_table.pccdailytransactionreportt.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_pccdailytransactionreportt_policy_read" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_read.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_read.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_read.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70
  }
}

# Adding resource and policy for Write Autoscaling
resource "aws_appautoscaling_target" "dynamodb_table_pccdailytransactionreportt_write" {
  max_capacity       = 100
  min_capacity       = 10
  resource_id        = "table/${aws_dynamodb_table.pccdailytransactionreportt.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_pccdailytransactionreportt_policy_write" {
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_write.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_write.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_write.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_pccdailytransactionreportt_write.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70
  }
}

# Adding IAM roles
resource "aws_iam_role" "pcc_dailytransactionFn-role-v0fpf6ka" {
  name = "pcc_dailytransactionFn-role-v0fpf6ka"
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}


# Adding IAM Policies
resource "aws_iam_policy" "AWSLambdaBasicExecutionRole-36645b1f-1f0a-4d17-a9cb-decccf697c76" {
  name = "AWSLambdaBasicExecutionRole-36645b1f-1f0a-4d17-a9cb-decccf697c76"
  path = "/service-role/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "logs:CreateLogGroup",
      "Effect": "Allow",
      "Resource": "arn:aws:logs:us-east-1:439712476071:*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": [
         "arn:aws:logs:*:*:*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}



# Adding IAM Policy attachments
resource "aws_iam_role_policy_attachment" "pcc_dailytransactionFn-role-v0fpf6ka_AWSLambdaBasicExecutionRole-36645b1f-1f0a-4d17-a9cb-decccf697c76" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = "pcc_dailytransactionFn-role-v0fpf6ka"
}

resource "aws_iam_role_policy_attachment" "pcc_dailytransactionFn-role-v0fpf6ka_AmazonDynamoDBFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = "pcc_dailytransactionFn-role-v0fpf6ka"
}

resource "aws_iam_role_policy_attachment" "pcc_dailytransactionFn-role-v0fpf6ka_AmazonS3FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = "pcc_dailytransactionFn-role-v0fpf6ka"
}

# Adding S3 buckets as trigger to lambda and giving the permissions
resource "aws_s3_bucket_notification" "aws-lambda-transactions-trigger" {
  bucket = aws_s3_bucket.pccdailytransactionreport.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.pcc_dailytransactionFn.arn
    events              = ["s3:ObjectCreated:Put"]
  }
  depends_on = [aws_lambda_permission.lambda-transactions-permission]
}

resource "aws_lambda_permission" "lambda-transactions-permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pcc_dailytransactionFn.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.pccdailytransactionreport.id}"
}



