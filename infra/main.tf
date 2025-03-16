module "ingestion" {
    source = "./ingestion"

    ingestion_api  = {
      dist_dir = "../src/dist/api"
      handler = "index.handler"
      name = "ingest-api"
    }
    
    application = var.application
    environment = var.environment
    domain = var.domain
    subdomain = var.subdomain
}

module "timeseries_store" {
    source = "./timeseries-store"
    
    application = var.application
    environment = var.environment

    source_stream = module.ingestion.events_stream

    seed_raw_table  = {
      dist_dir = "../src/dist/table-seeding/lambda-handlers"
      handler = "seed-raw-events-table.handler"
      name = "seed-raw-events-table"
    }

    handle_hourly_rollup = {
      dist_dir = "../src/dist/trend-analysis/lambda-handlers"
      handler = "handle-hourly-roll-up.handler"
      name = "handle-hourly-roll-up"
    }
}

