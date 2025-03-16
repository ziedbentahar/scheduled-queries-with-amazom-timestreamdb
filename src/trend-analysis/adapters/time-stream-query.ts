/**
 * This file is based on the example from here: https://github.com/awslabs/amazon-timestream-tools/blob/master/sample_apps/js/query-example.js
 */
import { QueryResponse, Datum, ColumnInfo, Row } from "@aws-sdk/client-timestream-query";

interface TimestreamRow {
    [key: string]: string;
}

const parseQueryResult = (queryResult: QueryResponse): Array<TimestreamRow> => {
    const columnInfo = queryResult.ColumnInfo!;
    const rows = queryResult.Rows!;

    const data: Array<TimestreamRow> = [];
    rows.forEach(function (row) {
        data.push(parseRow(columnInfo, row));
    });

    return data;
};

const parseRow = (columnInfo: ColumnInfo[], row: Row | undefined) => {
    let rowObject = {};
    if (row !== undefined) {
        const data = row.Data || [];

        // Join all columns in the row into one object.
        for (let i = 0; i < data.length; i++) {
            const datum = parseDatum(columnInfo[i], data[i]);
            rowObject = { ...rowObject, ...datum };
        }
    }

    return rowObject;
};

function parseDatum(info: ColumnInfo, datum: Datum): Record<string, unknown> {
    const columnName = parseColumnName(info);

    if ("NullValue" in datum && datum.NullValue === true) {
        return { [columnName]: null };
    }

    const columnType = info.Type!;

    // If the column is of TimeSeries Type
    if (columnType.TimeSeriesMeasureValueColumnInfo !== undefined) {
        return parseTimeSeries(columnName, datum);
    }
    // If the column is of Array Type
    if (columnType.ArrayColumnInfo !== undefined) {
        const arrayValues = datum.ArrayValue;
        if (info.Type!.ArrayColumnInfo && arrayValues) {
            return {
                [columnName]: parseArray(info.Type!.ArrayColumnInfo, arrayValues),
            };
        }
    }
    // If the column is of Row Type
    if (columnType.RowColumnInfo !== undefined) {
        const rowColumnInfo = columnType.RowColumnInfo;
        const rowValues = datum.RowValue;
        return parseRow(rowColumnInfo, rowValues);
    }

    // Then we must have a Scalar
    return parseScalarType(columnName, datum);
}

function parseTimeSeries(columnName: string, datum: Datum) {
    const returnVal = {
        [columnName]: "",
    };
    if (datum.TimeSeriesValue) {
        returnVal[columnName] = datum.TimeSeriesValue[0].Value!.ScalarValue ?? "";
    }
    return returnVal;
}

function parseScalarType(columnName: string, datum: Datum) {
    const value = datum.ScalarValue;
    return {
        [columnName]: value,
    };
}

function parseColumnName(info: ColumnInfo) {
    return info.Name == null ? "" : `${info.Name}`;
}

function parseArray(arrayColumnInfo: ColumnInfo, arrayValues: Datum[]) {
    const arrayOutput: Record<string, unknown>[] = [];
    arrayValues.forEach(function (datum) {
        arrayOutput.push(parseDatum(arrayColumnInfo, datum));
    });
    return arrayOutput;
}

export { TimestreamRow, parseQueryResult };
