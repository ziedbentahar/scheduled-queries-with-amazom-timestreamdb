resource "aws_cloudwatch_log_group" "pipes" {
  name              = "/aws/pipes/${var.application}-${var.environment}-kinesis-to-timestream"
  retention_in_days = "3"
}

resource "awscc_iam_role" "pipe" {
  assume_role_policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "pipes.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
  policies = [{
    policy_name = "kinesis-to-timestream"
    policy_document = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary",
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:ListShards",
            "kinesis:ListStreams",
            "kinesis:SubscribeToShard"
          ]
          Resource = ["${var.source_stream.arn}"]
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
        },
        {
          Effect = "Allow"
          Action = [
            "logs:PutLogEvents"
          ]
          Resource = [
            aws_cloudwatch_log_group.pipes.arn,
          ]
        }
      ]
    })
  }]
}

resource "awscc_pipes_pipe" "kinesis_to_timestream" {
  name     = "${var.application}-${var.environment}-kinesis-to-timestream"
  role_arn = awscc_iam_role.pipe.arn
  source   = var.source_stream.arn
  target   = aws_timestreamwrite_table.events_table.arn

  source_parameters = {
    kinesis_stream_parameters = {
      starting_position      = "TRIM_HORIZON"
      maximum_retry_attempts = 5
    }

    filter_criteria = {
      filters = [{
        pattern = <<EOF
{
  "data": {
    "eventType": ["pageViewed", "productPageShared", "productInquiryRequested"]
  }
}
EOF
      }]
    }
  }

  target_parameters = {
    timestream_parameters = {
      timestamp_format = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
      version_value    = "1"
      time_value       = "$.data.time"
      time_field_type  = "TIMESTAMP_FORMAT"

      single_measure_mappings = [{
          measure_name      = "$.data.eventType"
          measure_value     = "$.data.value"
          measure_value_type = "BIGINT"
      }]

      dimension_mappings = [
        {
          dimension_name       = "id"
          dimension_value      = "$.data.id"
          dimension_value_type = "VARCHAR"
        },
        {
          dimension_name       = "pageId"
          dimension_value      = "$.data.pageId"
          dimension_value_type = "VARCHAR"
        },
        {
          dimension_name       = "productId"
          dimension_value      = "$.data.productId"
          dimension_value_type = "VARCHAR"
        }
      ]
    }
  }
}
