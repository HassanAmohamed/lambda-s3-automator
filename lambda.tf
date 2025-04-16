# Data sources for current region and account ID
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "my-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  description        = "IAM role for the Lambda function"
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM Policy Document for Assume Role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Lambda Function
resource "aws_lambda_function" "my_lambda_function" {
  function_name    = "my-lambda-function"
  description      = "Processes incoming files from S3 bucket"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  filename         = data.archive_file.lambda_code.output_path
  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME       = "inbound-bucket-custome03"
      BUCKET_PATH       = "incoming/"
      LOG_LEVEL         = "INFO"
      MAX_RETRY_ATTEMPTS = "3"
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_role_policy_attachment,
    aws_iam_role_policy_attachment.lambda_xray_access,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Dead Letter Queue for failed invocations
resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "lambda-dlq"
  delay_seconds             = 900
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = "production"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/my-lambda-function"
  retention_in_days = 30
}

# IAM Policies and Attachments
resource "aws_iam_policy" "lambda_xray" {
  name        = "lambda_xray_policy"
  description = "IAM policy for X-Ray access from Lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-access-policy"
  description = "Allows Lambda to access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::inbound-bucket-custome03",
          "arn:aws:s3:::inbound-bucket-custome03/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_xray.arn
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = "inbound-bucket-custome03"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ],
        Resource = "arn:aws:s3:::inbound-bucket-custome03/*",
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:my-lambda-function"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "s3:ListBucket",
        Resource = "arn:aws:s3:::inbound-bucket-custome03"
      }
    ]
  })
}

# Archive File for Lambda Code
data "archive_file" "lambda_code" {
  type        = "zip"
  source_dir  = "lambda_functions/"
  output_path = "lambda_code.zip"
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = "inbound-bucket-custome03"

  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}

# Lambda Permission for S3
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::inbound-bucket-custome03"
}

# Monitoring Resources
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-my-lambda-function-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This alarm monitors Lambda function errors"
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.my_lambda_function.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
}

resource "aws_sns_topic" "lambda_alerts" {
  name = "lambda-error-alerts"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
}