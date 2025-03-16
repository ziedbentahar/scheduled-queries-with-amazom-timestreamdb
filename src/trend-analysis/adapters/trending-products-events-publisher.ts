import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";
import { randomUUID } from "crypto";
import { TrendingProducts } from "trend-analysis/models/trending-products-last-hour";

const snsClient = new SNSClient({
    region: process.env.AWS_REGION,
});

const publishTrendingProductsEvent = async (trendingProducts: TrendingProducts) => {
    const params = {
        Message: JSON.stringify({
            specversion: "1.0",
            id: randomUUID(),
            time: new Date().toISOString(),
            type: "hourlyTopTrendingProductsIdentified",
            source: "product-trend-analysis",
            data: trendingProducts,
        }),
        TopicArn: process.env.TRENDING_PRODUCTS_EVENTS_TOPIC_ARN,
    };

    const result = await snsClient.send(new PublishCommand(params));

};

export { publishTrendingProductsEvent };
