resource "aws_iam_role" "seed_raw_table" {
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

resource "aws_iam_policy" "seed_raw_table" {
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
          "timestream:WriteRecords",
        ]
        Resource = [
          "${aws_timestreamwrite_table.events_table.arn}",
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
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "seed_raw_table" {
  role       = aws_iam_role.seed_raw_table.name
  policy_arn = aws_iam_policy.seed_raw_table.arn
}

data "archive_file" "seed_raw_table" {
  type        = "zip"
  source_dir  = var.seed_raw_table.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-dist-zips/${var.seed_raw_table.name}.zip"
}

resource "aws_lambda_function" "seed_raw_table" {
  function_name    = "${var.application}-${var.environment}-${var.seed_raw_table.name}"
  filename         = data.archive_file.seed_raw_table.output_path
  role             = aws_iam_role.seed_raw_table.arn
  handler          = var.seed_raw_table.handler
  source_code_hash = filebase64sha256("${data.archive_file.seed_raw_table.output_path}")
  runtime          = "nodejs22.x"
  memory_size      = "256"
  architectures    = ["arm64"]


  logging_config {
    system_log_level      = "WARN"
    application_log_level = "ERROR"
    log_format            = "JSON"
  }

  environment {
    variables = {
      EVENTS_WRITE_TABLE = aws_timestreamwrite_table.events_table.table_name,
      EVENTS_DATABASE    = aws_timestreamwrite_table.events_table.database_name,
    }
  }
}

resource "aws_cloudwatch_log_group" "seed_raw_table" {
  name              = "/aws/lambda/${aws_lambda_function.seed_raw_table.function_name}"
  retention_in_days = "3"
}