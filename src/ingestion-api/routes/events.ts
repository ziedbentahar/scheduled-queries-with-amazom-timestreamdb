import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { publishEvents } from "../adapters/events-publisher";
import { Event, EventSchema } from "../schemas/events";
import { z } from "zod";

const arrayOfEventsSchema = z
    .any()
    .array()
    .max(42)
    .transform((array) =>
        array.map((item) => (EventSchema.safeParse(item).success ? item : undefined)).filter(Boolean)
    );

export const eventsHandling = new Hono().post("/", zValidator("json", arrayOfEventsSchema), async (c) => {
    // Ideal case: Only valid events are kept.
    // Invalid events should be handled properly, for example, by sending them to a Dead Letter Queue (DLQ) for later investigation.
    const validatedEvents = c.req.valid("json") as Event[];

    if (validatedEvents.length > 0) {
        await publishEvents(validatedEvents);
    }

    return c.body("", 201);
});
