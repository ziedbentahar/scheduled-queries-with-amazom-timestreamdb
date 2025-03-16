import { z } from "zod";

export const EventSchema = z.object({
    pageId: z.string(),
    productId: z.string(),
    eventType: z.enum([
        "pageViewed",
        "addToCartClicked",
        "productPageShared",
        "productDetailsFormOpened",
        "contactRequestSubmitted",
    ]),
});

export type Event = z.infer<typeof EventSchema>;
