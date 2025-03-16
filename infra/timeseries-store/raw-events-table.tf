resource "aws_timestreamwrite_table" "events_table" {

  database_name = aws_timestreamwrite_database.events_db.database_name
  table_name    = "${var.application}${var.environment}table"

  retention_properties {
    memory_store_retention_period_in_hours  = 48
    magnetic_store_retention_period_in_days = 30
  }

  schema {
    composite_partition_key {
      name = "productId"
      type = "DIMENSION"
    }
  }
}

resource "aws_lambda_invocation" "seed_raw_events_table" {

  function_name = aws_lambda_function.seed_raw_table.function_name
  input         = jsonencode({})

  depends_on = [
    aws_lambda_function.seed_raw_table,
    aws_timestreamwrite_table.events_table
  ]

  lifecycle_scope = "CREATE_ONLY"

}
