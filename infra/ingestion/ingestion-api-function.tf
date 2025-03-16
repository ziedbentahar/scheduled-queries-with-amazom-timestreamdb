
resource "aws_iam_role" "ingestion_api" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ingestion_api" {
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
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary",
            "kinesis:DescribeStreamConsumer",
            "kinesis:PutRecords"
        ]
        Resource = ["${aws_kinesis_stream.this.arn}"]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ingestion_api" {
  role       = aws_iam_role.ingestion_api.name
  policy_arn = aws_iam_policy.ingestion_api.arn
}

data "archive_file" "ingestion_api" {
  type        = "zip"
  source_dir  = var.ingestion_api.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-dist-zips/${var.ingestion_api.name}.zip"
}

resource "aws_lambda_function" "ingestion_api" {
  function_name    = "${var.application}-${var.environment}-${var.ingestion_api.name}"
  filename         = data.archive_file.ingestion_api.output_path
  role             = aws_iam_role.ingestion_api.arn
  handler          = var.ingestion_api.handler
  source_code_hash = filebase64sha256("${data.archive_file.ingestion_api.output_path}")
  runtime          = "nodejs22.x"
  memory_size      = "1756"
  timeout = 10

  architectures = ["arm64"]

  logging_config {
    system_log_level      = "WARN"
    application_log_level = "ERROR"
    log_format            = "JSON"
  }

  environment {
    variables = {
      CLICKSTREAM_TOPIC = aws_kinesis_stream.this.name
    }
  }
}

resource "aws_cloudwatch_log_group" "ingestion_api_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.ingestion_api.function_name}"
  retention_in_days = "3"
}


resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.ingestion_api.function_name
  authorization_type = "AWS_IAM"
}