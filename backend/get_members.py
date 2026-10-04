import json
import logging
import os
from decimal import Decimal

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Reuse the DynamoDB connection across requests handled by this Lambda instance.
members_table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _json_default(value):
    # DynamoDB returns numbers as Decimal; JSON needs int or float values.
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)
    raise TypeError("Unsupported JSON value")


def _scan_members():
    members = []
    scan_arguments = {}

    # A scan can return multiple pages, so collect records until no cursor remains.
    while True:
        response = members_table.scan(**scan_arguments)
        members.extend(response.get("Items", []))

        last_evaluated_key = response.get("LastEvaluatedKey")
        if not last_evaluated_key:
            return members

        # Resume the next scan after the final record from this page.
        scan_arguments["ExclusiveStartKey"] = last_evaluated_key


def _json_response(status_code, body):
    # API Gateway expects the response body to be a JSON string.
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=_json_default),
    }


def lambda_handler(event, context):
    try:
        members = _scan_members()

        # Member photos are served by CloudFront using the student ID as the filename.
        for member in members:
            student_id = member["studentId"]
            member["imagePath"] = (
                f"{os.environ['IMAGE_BASE_URL'].rstrip('/')}/images/{student_id}.jpg"
            )

        logger.info("Members scan completed; returned %d item(s)", len(members))
        return _json_response(200, members)
    except Exception as error:
        # Log details in CloudWatch, but do not expose them in the API response.
        logger.exception("Members scan failed (%s)", type(error).__name__)
        return _json_response(500, {"message": "Internal server error"})