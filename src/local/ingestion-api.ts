import { serve } from "@hono/node-server";
import { app } from "../ingestion-api/index";

serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        console.log(`Ingestion api is running on http://localhost:${info.port}`);
    }
);
