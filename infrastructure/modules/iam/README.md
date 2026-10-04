# IAM

Owns the Lambda execution role and its VPC and DynamoDB policies. Table access remains limited to `dynamodb:Scan` on the supplied `table_arn`.

The `execution_role_arn` output waits for required policies so the Lambda module can safely depend on it without a broad module dependency.

Inherits the root AWS provider. Apply through the root module; credentials are not module inputs.