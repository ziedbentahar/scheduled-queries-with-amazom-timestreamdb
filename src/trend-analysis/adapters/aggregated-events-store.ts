import { TimestreamQueryClient, QueryCommand } from "@aws-sdk/client-timestream-query";
import { NodeHttpHandler } from "@smithy/node-http-handler";
import { parseQueryResult } from "./time-stream-query";
import { TrendingProducts } from "trend-analysis/models/trending-products-last-hour";

const db = process.env.DB_NAME;
const table = process.env.TABLE_NAME;

const requestHandler = new NodeHttpHandler({
    // https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/client/timestream-query/command/QueryCommand/#:~:text=Query%20will%20time,for%20details.
    connectionTimeout: 60 * 1000,
    requestTimeout: 60 * 1000, // 60 seconds query timeout
});

const timestreamQueryClient = new TimestreamQueryClient({
    requestHandler,
});

const getTopNProduct = async (params: { eventType: string; topN: number }): Promise<TrendingProducts> => {
    const { eventType, topN } = params;

    const qs = `
WITH LastHour AS (
    SELECT 
        productId, 
        sum_measure AS current_views
    FROM "${db}"."${table}" 
    WHERE measure_name = '${eventType}'
        AND time > ago(1h)
),
PreviousHour AS (
    SELECT 
        productId, 
        sum_measure AS previous_views
    FROM "${db}"."${table}" 
    WHERE measure_name = '${eventType}' 
        AND time > ago(2h) 
        AND time <= ago(1h)
)
SELECT 
    l.productId, 
    l.current_views, 
    COALESCE(p.previous_views, 0) AS previous_views, 
    (l.current_views - COALESCE(p.previous_views, 0)) AS increase_last_hour
FROM LastHour l
LEFT JOIN PreviousHour p ON l.productId = p.productId
WHERE (l.current_views >= COALESCE(p.previous_views, 0) * 2)
ORDER BY increase_last_hour DESC
LIMIT ${topN}
`;

    //const result = await runQuery(qs);

    const queryResult = await timestreamQueryClient.send(
        new QueryCommand({
            QueryString: qs,
        })
    );

    const result = parseQueryResult(queryResult);

    return {
        eventType,
        time: new Date().toISOString(),
        products: result.map((row) => ({
            productId: row.productId,
            count: Number(row.current_views),
            increaseLastHour: Number(row.increase_last_hour),
        })),
    };
};

export { getTopNProduct };
