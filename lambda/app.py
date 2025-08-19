import json
import os
import boto3

TABLE_NAME = os.environ.get("TABLE_NAME", "ItemsTable")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    method = event["requestContext"]["http"]["method"]
    
    if method == "POST":
        body_str = event.get("body")
        if not body_str:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing body"})}
        
        body = json.loads(body_str)
        table.put_item(Item={"id": body["id"], "value": body["value"]})
        return {"statusCode": 200, "body": json.dumps({"message": "Item added"})}
    
    elif method == "GET":
        params = event.get("queryStringParameters") or {}
        item_id = params.get("id")
        if not item_id:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing id parameter"})}
        
        response = table.get_item(Key={"id": item_id})
        return {"statusCode": 200, "body": json.dumps(response.get("Item", {}))}
    
    return {"statusCode": 400, "body": json.dumps({"error": "Invalid request"})}
