resource "aws_iam_role" "handle_hourly_rollup" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "handle_hourly_rollup" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "timestream:Select",
        ]
        Resource = [
          aws_timestreamwrite_table.hourly_rollup.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "timestream:DescribeEndpoints"
        ]
        Resource = [
          "*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = [aws_sns_topic.trending_products_topic.arn]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "handle_hourly_rollup" {
  role       = aws_iam_role.handle_hourly_rollup.name
  policy_arn = aws_iam_policy.handle_hourly_rollup.arn
}

data "archive_file" "handle_hourly_rollup" {
  type        = "zip"
  source_dir  = var.handle_hourly_rollup.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-dist-zips/${var.handle_hourly_rollup.name}.zip"
}

resource "aws_lambda_function" "handle_hourly_rollup" {
  function_name    = "${var.application}-${var.environment}-${var.handle_hourly_rollup.name}"
  filename         = data.archive_file.handle_hourly_rollup.output_path
  role             = aws_iam_role.handle_hourly_rollup.arn
  handler          = var.handle_hourly_rollup.handler
  source_code_hash = filebase64sha256("${data.archive_file.handle_hourly_rollup.output_path}")
  runtime          = "nodejs22.x"
  memory_size      = "256"
  architectures    = ["arm64"]

  logging_config {
    system_log_level      = "WARN"
    application_log_level = "WARN"
    log_format            = "JSON"
  }

  environment {
    variables = {
      TABLE_NAME  = aws_timestreamwrite_table.hourly_rollup.table_name,
      DB_NAME     = aws_timestreamwrite_table.hourly_rollup.database_name,
      TRENDING_PRODUCTS_EVENTS_TOPIC_ARN = aws_sns_topic.trending_products_topic.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "handle_hourly_rollup" {
  name              = "/aws/lambda/${aws_lambda_function.handle_hourly_rollup.function_name}"
  retention_in_days = "3"
  
}


resource "aws_sns_topic_subscription" "handle_hourly_rollup" {
  topic_arn = aws_sns_topic.scheduled_query_notification_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.handle_hourly_rollup.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handle_hourly_rollup.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scheduled_query_notification_topic.arn
}