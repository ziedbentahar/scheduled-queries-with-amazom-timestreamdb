import { Hono } from "hono";
import { handle } from "hono/aws-lambda";
import { eventsHandling } from "./routes/events";

export const app = new Hono();

app.route("/events", eventsHandling);

export const handler = handle(app);
