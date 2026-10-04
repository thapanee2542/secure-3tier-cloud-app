# S3

Owns the private frontend bucket, ownership controls, encryption, public-access block, objects, and CloudFront-only bucket policy. Insecure transport is denied and automatic bucket emptying is disabled.

Inputs provide deployment identifiers, the CloudFront ARN, root-relative asset directories, stable file collections, and content types. Outputs: `bucket_name` and `bucket_regional_domain_name`.

The root discovers files and passes their paths explicitly so moving HCL into this directory does not change S3 object keys or local asset paths. Apply through the root module with its inherited AWS provider.