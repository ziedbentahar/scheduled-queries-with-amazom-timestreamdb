import { SNSEvent, SNSHandler, SNSEventRecord } from "aws-lambda";
import { ScheduledQueryResult } from "./types.js";
import { getTopNProduct } from "../adapters/aggregated-events-store.js";
import { publishTrendingProductsEvent } from "trend-analysis/adapters/trending-products-events-publisher.js";

export const handler: SNSHandler = async (event: SNSEvent): Promise<void> => {
    const successNotification = event.Records.some((record: SNSEventRecord) => {
        const message = JSON.parse(record.Sns.Message) as ScheduledQueryResult;

        if (message.type === "MANUAL_TRIGGER_SUCCESS" || message.type === "AUTO_TRIGGER_SUCCESS") {
            return true;
        }
    });

    if (successNotification) {
        const trendingProducts = await getTopNProduct({
            eventType: "pageViewed",
            topN: 10,
        });

        if (trendingProducts) {
            await publishTrendingProductsEvent(trendingProducts);
        }
    }
};
