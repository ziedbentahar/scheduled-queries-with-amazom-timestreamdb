resource "aws_sns_topic" "trending_products_topic" {
    name = "${var.application}-${var.environment}-trending-products"
}