type NotificationType = "MANUAL_TRIGGER_SUCCESS" | "FAILED" | "RUNNING"; // Extend with other statuses if needed

export type ScheduledQueryResult =
    | {
          type: "MANUAL_TRIGGER_SUCCESS" | "AUTO_TRIGGER_SUCCESS";
          arn: string;
          nextInvocationEpochSecond: number;
          scheduledQueryRunSummary: {
              invocationEpochSecond: number;
              triggerTimeMillis: number;
              runStatus: NotificationType;
              executionStats: {
                  executionTimeInMillis: number;
                  dataWrites: number;
                  bytesMetered: number;
                  cumulativeBytesScanned: number;
                  recordsIngested: number;
                  queryResultRows: number;
              };
          };
      }
    | {
          type: "AUTO_TRIGGER_FAILURE" | "MANUAL_TRIGGER_FAILURE";
          arn: string;
      };
