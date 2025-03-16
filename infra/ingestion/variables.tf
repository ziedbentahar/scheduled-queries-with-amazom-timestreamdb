variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "ingestion_api" {
  type = object({
    dist_dir = string
    handler  = string
    name     = string
  })
}

variable "domain" {
  type = string
}

variable "subdomain" {
  type = string
}