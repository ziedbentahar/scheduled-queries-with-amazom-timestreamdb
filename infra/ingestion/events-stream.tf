resource "aws_kinesis_stream" "this" {
  name             = "${var.application}-${var.environment}-events"
  retention_period = 24

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
}
