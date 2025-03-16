import {
    MeasureValueType,
    TimeUnit,
    TimestreamWriteClient,
    WriteRecordsCommand,
} from "@aws-sdk/client-timestream-write";
import { randomUUID } from "crypto";

const timeStreamWriteClient = new TimestreamWriteClient({});

export const handler = async (_: unknown): Promise<void> => {
    await timeStreamWriteClient.send(
        new WriteRecordsCommand({
            DatabaseName: process.env.EVENTS_DATABASE,
            TableName: process.env.EVENTS_WRITE_TABLE,

            Records: [
                {
                    Dimensions: [
                        {
                            Name: "pageId",
                            Value: "-",
                            DimensionValueType: MeasureValueType.VARCHAR,
                        },
                        {
                            Name: "productId",
                            Value: "-",
                            DimensionValueType: MeasureValueType.VARCHAR,
                        },
                        {
                            Name: "id",
                            Value: randomUUID(),
                            DimensionValueType: MeasureValueType.VARCHAR,
                        },
                    ],
                    MeasureName: "dummyEvent",
                    MeasureValueType: MeasureValueType.BIGINT,
                    MeasureValue: "1",
                    Time: Date.now().toString(),
                    TimeUnit: TimeUnit.MILLISECONDS,
                },
            ],
        })
    );
};
