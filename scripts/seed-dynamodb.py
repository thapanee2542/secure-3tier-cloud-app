#!/usr/bin/env python3
"""
Seed DynamoDB Members table with sample data

Usage:
    python scripts/seed-dynamodb.py --table-name Members --region us-east-1
    
This script reads member data from a local JSON file and uploads it to DynamoDB.
"""

import json
import argparse
import logging
import sys
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Sample member data
SAMPLE_MEMBERS = [
    {
        "id": "member-001",
        "name": "Alice Johnson",
        "role": "Project Lead & Full-Stack Engineer",
        "bio": "Expert in cloud security architecture and serverless patterns. Leader in infrastructure as code, VPC design, and least-privilege IAM policies.",
        "photoKey": "photos/alice-johnson.jpg",
    },
    {
        "id": "member-002",
        "name": "Bob Chen",
        "role": "Backend & Security Specialist",
        "bio": "Focused on Lambda security, DynamoDB encryption, and API Gateway authorization. Implements secure data pipelines, audit logging, and encryption at rest.",
        "photoKey": "photos/bob-chen.jpg",
    },
    {
        "id": "member-003",
        "name": "Carol Martinez",
        "role": "Frontend & DevOps Engineer",
        "bio": "Specializes in React performance optimization, CloudFront CDN configuration, and CI/CD pipeline automation. Ensures secure and efficient media delivery.",
        "photoKey": "photos/carol-martinez.jpg",
    },
    {
        "id": "member-004",
        "name": "Diana Patel",
        "role": "Cloud Architect & Documentation Lead",
        "bio": "Designs resilient, scalable, cost-effective AWS architectures. Expert in VPC design patterns, DynamoDB optimization, comprehensive documentation, and disaster recovery.",
        "photoKey": "photos/diana-patel.jpg",
    },
]


def create_dynamodb_client(region: str) -> object:
    """Create DynamoDB resource"""
    try:
        dynamodb = boto3.resource('dynamodb', region_name=region)
        logger.info(f"Connected to AWS region: {region}")
        return dynamodb
    except ClientError as e:
        logger.error(f"Failed to connect to AWS: {e}")
        sys.exit(1)


def seed_table(table_name: str, members: list, region: str) -> bool:
    """Seed DynamoDB table with member data"""
    try:
        dynamodb = create_dynamodb_client(region)
        table = dynamodb.Table(table_name)

        # Verify table exists by describing it
        logger.info(f"Connecting to table: {table_name}")
        table.load()
        logger.info(f"Table status: {table.table_status}")

        # Insert members
        logger.info(f"Inserting {len(members)} members into {table_name}...")
        
        with table.batch_writer(
            overwrite_by_pkeys=['id']
        ) as batch:
            for member in members:
                batch.put_item(Item=member)
                logger.info(f"  ✓ Inserted: {member['name']} ({member['id']})")

        logger.info(f"✓ Successfully seeded {len(members)} members")
        return True

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        
        if error_code == 'ResourceNotFoundException':
            logger.error(f"Table not found: {table_name}")
            logger.error("Make sure you've run 'terraform apply' to create the table first")
        else:
            logger.error(f"DynamoDB error ({error_code}): {error_msg}")
        
        return False
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return False


def load_members_from_file(filepath: str) -> list:
    """
    Load member data from JSON file
    Falls back to SAMPLE_MEMBERS if file not found
    """
    if not Path(filepath).exists():
        logger.warning(f"Members file not found: {filepath}")
        logger.info(f"Using built-in sample data ({len(SAMPLE_MEMBERS)} members)")
        return SAMPLE_MEMBERS

    try:
        with open(filepath, 'r') as f:
            members = json.load(f)
        logger.info(f"Loaded {len(members)} members from {filepath}")
        return members
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in {filepath}: {e}")
        logger.info("Using built-in sample data instead")
        return SAMPLE_MEMBERS


def main():
    parser = argparse.ArgumentParser(
        description="Seed DynamoDB Members table with sample data"
    )
    parser.add_argument(
        '--table-name',
        required=True,
        help='DynamoDB table name'
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )
    parser.add_argument(
        '--members-file',
        default='data/members.json',
        help='Path to JSON file with member data (default: data/members.json)'
    )
    parser.add_argument(
        '--use-sample',
        action='store_true',
        help='Use built-in sample data (ignore members-file)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be inserted without actually seeding'
    )

    args = parser.parse_args()

    # Load member data
    if args.use_sample:
        members = SAMPLE_MEMBERS
    else:
        members = load_members_from_file(args.members_file)

    # Validate member data
    required_fields = {'id', 'name', 'role', 'bio', 'photoKey'}
    for member in members:
        if not required_fields.issubset(member.keys()):
            logger.error(f"Member missing required fields: {member}")
            logger.error(f"Required fields: {required_fields}")
            sys.exit(1)

    if args.dry_run:
        logger.info("DRY RUN - Would insert the following members:")
        for member in members:
            logger.info(f"  - {member['name']} (ID: {member['id']})")
        return

    # Seed the table
    success = seed_table(args.table_name, members, args.region)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
