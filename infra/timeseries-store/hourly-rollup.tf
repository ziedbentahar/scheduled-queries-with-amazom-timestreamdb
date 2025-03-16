locals {
  hourly_rollup_error_prefix = "hourly-rollup-error"
}

resource "random_string" "this" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}

resource "aws_s3_bucket" "error_bucket" {
  bucket        = "${var.application}-${var.environment}-scheduled-queries-errors-${random_string.this.id}"
  force_destroy = true
}

resource "aws_timestreamwrite_table" "hourly_rollup" {
  database_name = aws_timestreamwrite_database.events_db.database_name
  table_name    = "${var.application}${var.environment}hourlyrollup"

  retention_properties {
    magnetic_store_retention_period_in_days = 30
    memory_store_retention_period_in_hours  = 24
  }

  schema {
    composite_partition_key {
      name = "productId"
      type = "DIMENSION"
    }
  }
}

resource "aws_sns_topic" "scheduled_query_notification_topic" {
  name = "${var.application}-${var.environment}-scheduled-queries"
}


resource "aws_iam_role" "scheduled_query_role" {
  name = "${var.application}-${var.environment}-sq-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "timestream.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "scheduled_query_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "timestream:WriteRecords",
        ]
        Resource = [aws_timestreamwrite_table.hourly_rollup.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "timestream:Select",
        ]
        Resource = [aws_timestreamwrite_table.events_table.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = [aws_sns_topic.scheduled_query_notification_topic.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"

        ]
        Resource = ["${aws_s3_bucket.error_bucket.arn}/${local.hourly_rollup_error_prefix}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduled_query_policy_attachment" {
  role       = aws_iam_role.scheduled_query_role.name
  policy_arn = aws_iam_policy.scheduled_query_policy.arn
}

resource "aws_timestreamquery_scheduled_query" "hourly_rollup" {
  name = "${var.application}-${var.environment}-hourly-rollup"
  schedule_configuration {
    schedule_expression = "rate(1 hour)"
  }

  query_string = templatefile("${path.module}/queries/hourly-rollup.sql.tmpl", {
    table = "\"${aws_timestreamwrite_table.events_table.database_name}\".\"${aws_timestreamwrite_table.events_table.table_name}\""
  })


  target_configuration {
    timestream_configuration {
      database_name = aws_timestreamwrite_database.events_db.database_name
      table_name    = aws_timestreamwrite_table.hourly_rollup.table_name
      time_column   = "time"

      dimension_mapping {
        name                 = "pageId"
        dimension_value_type = "VARCHAR"
      }
      dimension_mapping {
        name                 = "productId"
        dimension_value_type = "VARCHAR"
      }
      measure_name_column = "eventType"
      multi_measure_mappings {
        target_multi_measure_name = "eventType"
        multi_measure_attribute_mapping {
          source_column      = "sum_measure"
          measure_value_type = "BIGINT"
        }
      }
    }
  }

  execution_role_arn = aws_iam_role.scheduled_query_role.arn

  error_report_configuration {
    s3_configuration {
      bucket_name = aws_s3_bucket.error_bucket.id
      object_key_prefix = local.hourly_rollup_error_prefix
    }
  }

  notification_configuration {
    sns_configuration {
      topic_arn = aws_sns_topic.scheduled_query_notification_topic.arn
    }
  }

  depends_on = [
    aws_lambda_invocation.seed_raw_events_table,
  ]
}
