import json

def lambda_handler(event, context):
    """
    A simple AWS Lambda function that returns a greeting message.

    Parameters:
    - event: The event data (passed from API Gateway or other triggers).
    - context: The runtime information for the Lambda function.

    Returns:
    A JSON response containing a greeting message.
    """
    # Log the event for debugging
    print("Received event:", json.dumps(event, indent=2))

    # Extract details from the event
    method = event.get("httpMethod", "UNKNOWN")
    path = event.get("path", "/")
    
    # Define responses for specific routes
    if method == "POST" and path == "/accretion-posting":
        response_body = {
            "message": "Accretion posting processed successfully!"
        }
    elif method == "POST" and path == "/depreciation-posting":
        response_body = {
            "message": "Depreciation posting processed successfully!"
        }
    else:
        response_body = {
            "error": "Invalid route or method."
        }

    # Return a response
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }
