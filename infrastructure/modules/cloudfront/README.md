# CloudFront

Owns the distribution and S3 Origin Access Control. Viewers are redirected to HTTPS; S3 access is signed, and API origin connections use HTTPS.

Inputs: project and environment names, private bucket regional domain, API domain, and stage name. Outputs: `base_url` and `distribution_arn`.

The S3 module owns the bucket policy and consumes the distribution ARN. This module consumes only the bucket domain, not the policy, so the resources can be ordered without a module cycle. Apply through the root module with its inherited AWS provider.