import json
import os
import boto3

TABLE_NAME = os.environ.get("TABLE_NAME", "ItemsTable")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    method = event["requestContext"]["http"]["method"]

    if method == "POST":
        body = json.loads(event["body"])
        table.put_item(Item={"id": body["id"], "value": body["value"]})
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Item added"})
        }

    elif method == "GET":
        item_id = event.get("queryStringParameters", {}).get("id")
        if not item_id:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing id"})}
        response = table.get_item(Key={"id": item_id})
        return {
            "statusCode": 200,
            "body": json.dumps(response.get("Item", {}))
        }

    return {"statusCode": 400, "body": json.dumps({"error": "Invalid request"})}
