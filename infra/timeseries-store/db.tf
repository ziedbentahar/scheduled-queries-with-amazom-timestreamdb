resource "aws_timestreamwrite_database" "events_db" {
  database_name = "${var.application}${var.environment}"
}

