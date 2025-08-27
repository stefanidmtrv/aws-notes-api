import json
import os
import pprint
import boto3
from aws_lambda_powertools.logging import Logger
from boto3.dynamodb.conditions import Key

# Initialize resources
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table("notes_table")
logger = Logger()

def get_user(user_id):
    """Retrieve a user from DynamoDB."""
    response = table.query(KeyConditionExpression=Key('user_id').eq(user_id))
    if 'Items' in response and response['Items']:
        item = response['Items'][0]
        return respond(200, {'user_id': user_id, 'user_name': item.get('user_name', 'Unknown'), 'note': item.get('note', '')})
    return respond(404, {'message': 'User not found'})


def save_user(body):
    """Save a user to DynamoDB."""
    user_id = body['user_id']
    user_name = body['user_name']
    note = body['note']
    
    table.put_item(Item={'user_id': user_id, 'user_name': user_name, 'note': note})
    return respond(200, {'message': 'User saved'})

def update_user(body):
    user_id = body['user_id']  # Partition key (always required)

    # Build update expression dynamically
    update_expr = []
    expr_attr_values = {}

    for key, value in body.items():
        if key != "user_id":  # don't update the PK
            update_expr.append(f"{key} = :{key}")
            expr_attr_values[f":{key}"] = value

    if not update_expr:
        return respond(400, {"message": "No attributes to update"})

    update_expression = "SET " + ", ".join(update_expr)

    # Update only the provided attributes
    response = table.update_item(
        Key={"user_id": user_id},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expr_attr_values,
        ReturnValues="UPDATED_NEW"
    )

    return respond(200, {
        "message": "User updated",
        "updated_attributes": response.get("Attributes", {})
    })


def delete_user(user_id):
    """Delete a user from DynamoDB."""
    # Check if the user exists
    existing_user = table.get_item(Key={'user_id': user_id})
    logger.info(f"Existing user: {existing_user}")
    if 'Item' not in existing_user:
        return respond(404, {'message': 'User not found'})
    
    response = table.delete_item(Key={'user_id': user_id})
    if response.get('ResponseMetadata', {}).get('HTTPStatusCode') == 200:
        return respond(200, {'message': 'User deleted'})
    return respond(404, {'message': 'User not found'})

def respond(status_code, body):
    """Helper function to create a response."""
    return {
        'statusCode': status_code,
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    logger.info(f"Event: {event}")
    """Main Lambda handler."""
    route = event["requestContext"]["http"]["path"]
    method = event["requestContext"]["http"]["method"]
    logger.info(f"Route: {route}, Method: {method}")

    try:
        if method == 'POST' and route == '/submit':
            body = json.loads(event['body'])
            return save_user(body)

        elif method == 'GET' and route == '/id':
            user_id = event['queryStringParameters']['user_id']
            return get_user(user_id)
        
        elif method == 'DELETE' and route == '/delete':
            user_id = event['queryStringParameters']['user_id']
            logger.info(f"User-id: {user_id}")
            return delete_user(user_id)
        
        elif method == 'PUT' and route == '/update':
            body = json.loads(event['body'])
            return update_user(body)
        logger.info(f"Route2: {route}, Method2: {method}")

        return respond(404, {'message': 'Not Found'})

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return respond(500, {'error': str(e)})
    
    
if __name__ == "__main__":
    print("Local test")
    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, '../test_event.json')
    
    f = open(file_path)
    test_event = json.load(f)
    
    result = lambda_handler(test_event, None)
    pprint.pprint(result)

