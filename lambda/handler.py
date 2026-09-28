"""
AWS Lambda Handler for GET /members API
Reads members from DynamoDB and returns formatted JSON response
"""
import json
import os
import logging
from typing import Any, Dict, List

import boto3
from botocore.exceptions import ClientError

# Initialize clients and logger
dynamodb = boto3.resource("dynamodb")
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
MEMBERS_TABLE = os.environ.get("MEMBERS_TABLE_NAME", "Members")
CLOUDFRONT_DOMAIN = os.environ.get("CLOUDFRONT_DOMAIN_URL", "")
CORS_ORIGIN = os.environ.get("CORS_ORIGIN", "*")


def get_table() -> Any:
    """Get DynamoDB table resource"""
    return dynamodb.Table(MEMBERS_TABLE)


def build_photo_url(photo_key: str) -> str:
    """
    Build the full CloudFront URL for a member's photo
    
    Args:
        photo_key: The S3 key for the photo (e.g., 'photos/alice-johnson.jpg')
    
    Returns:
        Full CloudFront HTTPS URL
    
    TODO(CLOUD): Ensure CLOUDFRONT_DOMAIN_URL is set in Lambda environment
    """
    if not CLOUDFRONT_DOMAIN:
        logger.warning(
            "CLOUDFRONT_DOMAIN_URL not configured; photos may not load correctly"
        )
        return f"https://CLOUDFRONT_DOMAIN_NOT_SET/{photo_key}"

    # Remove trailing slash from domain if present
    domain = CLOUDFRONT_DOMAIN.rstrip("/")
    return f"{domain}/{photo_key}"


def scan_members() -> List[Dict[str, Any]]:
    """
    Scan the Members table and return all members
    
    Returns:
        List of member dictionaries with generated photo URLs
    
    Raises:
        ClientError: If DynamoDB scan fails
    """
    try:
        table = get_table()
        logger.info(f"Scanning DynamoDB table: {MEMBERS_TABLE}")

        response = table.scan()

        members = []
        for item in response.get("Items", []):
            # Validate required fields
            required_fields = ["id", "name", "role", "bio", "photoKey"]
            if not all(field in item for field in required_fields):
                logger.warning(f"Skipping item with missing fields: {item}")
                continue

            # Build photo URL
            photo_url = build_photo_url(item["photoKey"])

            member = {
                "id": item["id"],
                "name": item["name"],
                "role": item["role"],
                "bio": item["bio"],
                "photoKey": item["photoKey"],
                "photoUrl": photo_url,
            }
            members.append(member)

        logger.info(f"Successfully retrieved {len(members)} members from DynamoDB")
        return members

    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        error_msg = e.response["Error"]["Message"]
        logger.error(f"DynamoDB error ({error_code}): {error_msg}")
        raise


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for GET /members API
    
    Args:
        event: API Gateway Lambda proxy event
        context: Lambda runtime context
    
    Returns:
        API Gateway Lambda proxy response
    
    Request format:
        GET /members
    
    Response format:
        {
            "success": true,
            "data": [
                {
                    "id": "member-001",
                    "name": "Alice Johnson",
                    "role": "Project Lead & Full-Stack Engineer",
                    "bio": "...",
                    "photoKey": "photos/alice-johnson.jpg",
                    "photoUrl": "https://d1234567.cloudfront.net/photos/alice-johnson.jpg"
                },
                ...
            ],
            "timestamp": "2024-01-15T10:30:45Z"
        }
    
    Error response format:
        {
            "success": false,
            "error": "Internal Server Error",
            "timestamp": "2024-01-15T10:30:45Z"
        }
    """
    from datetime import datetime, timezone

    try:
        logger.info(f"Received request: {event.get('requestContext', {}).get('http', {}).get('method')} {event.get('rawPath')}")

        # Verify HTTP method
        http_method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
        if http_method != "GET":
            logger.warning(f"Method not allowed: {http_method}")
            return create_error_response(405, "Method Not Allowed")

        # Fetch members from DynamoDB
        members = scan_members()

        # Build success response
        response_body = {
            "success": True,
            "data": members,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        logger.info("Request processed successfully")

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": CORS_ORIGIN,
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
                "Cache-Control": "public, max-age=300",  # Cache for 5 minutes
            },
            "body": json.dumps(response_body),
        }

    except ClientError as e:
        logger.exception("DynamoDB error occurred")
        return create_error_response(
            500,
            "Internal Server Error",
            "Failed to retrieve members from database",
        )
    except Exception as e:
        logger.exception(f"Unexpected error: {str(e)}")
        return create_error_response(500, "Internal Server Error")


def create_error_response(
    status_code: int, error: str, details: str = None
) -> Dict[str, Any]:
    """
    Create a standardized error response
    
    Args:
        status_code: HTTP status code
        error: Error message
        details: Optional detailed error message
    
    Returns:
        API Gateway Lambda proxy response
    """


    response_body = {
        "success": False,
        "error": error,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    if details:
        response_body["details"] = details

    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": CORS_ORIGIN,
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(response_body),
    }
