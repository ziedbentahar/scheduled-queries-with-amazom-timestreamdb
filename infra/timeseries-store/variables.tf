variable "application" {
  type    = string
}

variable "environment" {
  type    = string
}

variable "source_stream" {
    type = object({
      arn = string
    })
}

variable "seed_raw_table" {
  type = object({
    dist_dir = string
    handler = string
    name = string
  })
}

variable "handle_hourly_rollup" {
   type = object({
    dist_dir = string
    handler = string
    name = string
  })
}