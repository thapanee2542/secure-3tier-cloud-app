# DynamoDB

Creates the members table and demo records. Encryption and point-in-time recovery remain enabled. Member IDs and the fixed table name are retained for compatibility with the existing deployment.

Input: `members`, a map of student ID, name, and role objects keyed by member ID. Outputs: `table_name` and `table_arn`.

This module inherits the root AWS provider. Deploy through the infrastructure root; do not initialize separate state here.