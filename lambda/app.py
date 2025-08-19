import json
import os
import boto3

TABLE_NAME = os.environ.get("TABLE_NAME", "ItemsTable")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    print("Event:", json.dumps(event))  # Debug log

    # For HTTP API (v2), method is inside requestContext
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    if method == "POST":
        body = event.get("body")
        if body:
            data = json.loads(body)
            table.put_item(Item={"id": data["id"], "value": data["value"]})
            return {"statusCode": 200, "body": json.dumps({"message": "Item added"})}
        else:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing body"})}

    elif method == "GET":
        params = event.get("queryStringParameters") or {}
        item_id = params.get("id")
        if not item_id:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing id parameter"})}

        response = table.get_item(Key={"id": item_id})
        return {"statusCode": 200, "body": json.dumps(response.get("Item", {}))}

    return {"statusCode": 400, "body": json.dumps({"error": "Invalid request"})}
