# SNS

Owns the alarm notification topic, customer-managed KMS key and alias, source-restricted publishing policy, and email subscription. The policy grants CloudWatch publishing only for the supplied account, region, and project namespace; other same-account IAM grants must still be reviewed separately.

The topic encrypts messages at rest with the KMS key. Automatic key rotation is enabled and key deletion uses a 30-day waiting period. The key policy permits account administration and grants CloudWatch `kms:GenerateDataKey*` and `kms:Decrypt` only for the configured alarm namespace, so encryption does not remove alarm publishing permissions.

The topic policy denies insecure API transport for non-service principals. AWS service principals are excluded from this deny because transport context can be redacted in service-to-service requests; the source-restricted CloudWatch allow remains in place. This policy governs SNS API access, not email delivery. SNS encryption at rest does not provide end-to-end encryption of email notifications.

Inputs: project, environment, region, account ID, and notification email. Output: `topic_arn`. Confirm the email subscription after deployment.

The root deploys this module only when `enable_cloudwatch_alarms = true`, and passes `module.sns[0].topic_arn` to both alarms. When the flag is false, no SNS/KMS resources are configured. Switching an existing deployment off destroys its topic, policy, subscription, and alias and schedules key deletion after 30 days. The indexed module address is intended for fresh deployments; legacy unindexed addresses are not migrated automatically.

Inherits the root AWS provider. Apply through the root module; this folder does not have independent state.

From the infrastructure root, test with Terraform 1.7+:

```sh
terraform init
terraform test -filter=tests/sns_security.tftest.hcl
```

The test uses mocked AWS resources, including a mocked apply; it does not contact AWS or update deployment state. It verifies key selection and management settings, scoped KMS and publish permissions, and the HTTPS deny/service exemption.

Review the real Terraform plan before applying: this change adds a KMS key and alias and updates the topic encryption and access policy. KMS incurs charges. Confirm the SNS email subscription and test delivery from a real CloudWatch alarm after deployment; mocks cannot verify service-side permissions or email delivery.