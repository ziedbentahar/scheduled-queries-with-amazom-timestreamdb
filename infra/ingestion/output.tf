output "events_stream" {
   value = {
    arn        = aws_kinesis_stream.this.arn
  }
}