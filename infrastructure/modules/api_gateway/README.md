# API Gateway

Owns the regional members REST API, proxy integration, deployment, stage, throttling settings, and route-specific Lambda invocation permission.

Inputs: project and environment names, stage name, Lambda invocation ARN, and function name. Outputs: API ID, API name, stage name, and members URL. The API ID output intentionally references only the REST API, avoiding a cycle with CloudFront and Lambda.

The endpoint remains public with no authentication, as in the original configuration. Folder separation does not add access control. Authentication must be implemented separately before serving private data.

Inherits the root AWS provider. Deploy through the root module and review its deployment plan.