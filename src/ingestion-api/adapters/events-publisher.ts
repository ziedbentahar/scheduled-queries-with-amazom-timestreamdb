import { KinesisClient, PutRecordsCommand } from "@aws-sdk/client-kinesis";
import { randomUUID } from "crypto";
import { Event } from "ingestion-api/schemas/events";

const kinesisClient = new KinesisClient({});

const publishEvents = async (events: Event[]) => {
    await kinesisClient.send(
        new PutRecordsCommand({
            StreamName: process.env.CLICKSTREAM_TOPIC,
            Records: events.map((e) => {
                const id = randomUUID();
                const record = {
                    ...e,
                    id,
                    value: 1,
                    time: new Date().toISOString(),
                };
                return {
                    PartitionKey: record.id,
                    Data: Buffer.from(JSON.stringify(record)),
                };
            }),
        })
    );
};

export { publishEvents };
