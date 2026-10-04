# Lambda

Packages only the supplied Python handler and creates the private-subnet Lambda function. Source hashes trigger code updates; local tests and tools are excluded from the archive.

Inputs provide the function name, execution role, table name, image URL, private subnets, security group, source file, and archive path. Outputs: `function_name` and `invoke_arn`.

The root passes the function name through the CloudWatch log-group output and the execution role through the IAM readiness output, preserving creation order without cyclic whole-module dependencies. Providers are inherited from the root.