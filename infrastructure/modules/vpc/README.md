# VPC

Owns the VPC, two private subnets, routing, Lambda security group, and DynamoDB Gateway endpoint. There is no internet route; Lambda egress is limited to DynamoDB HTTPS. The endpoint policy restricts access to the supplied table and execution role.

Inputs: `project_name`, `environment`, `aws_region`, `table_arn`, and `execution_role_arn`. Outputs expose the VPC, subnets, route table, security group, endpoint, and prefix list identifiers.

Inherits the root AWS provider. Apply only through the root module and its existing state.