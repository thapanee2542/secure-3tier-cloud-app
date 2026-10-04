# CloudWatch

Owns the Lambda log group and API request/client-error alarms. Existing three-day log retention and alarm thresholds are preserved.

Inputs: project and environment names, API name, stage name, SNS topic ARN, `enable_log_group`, and `enable_metric_alarms`. Both deployment flags default to `true`.

Set the corresponding root inputs in your local `infrastructure/terraform.tfvars`:

```hcl
enable_cloudwatch_logs   = true
enable_cloudwatch_alarms = false
```

This deploys the managed Lambda log group but not the API alarms. Set both flags to `false` to deploy neither. The flags can also be provided through `TF_VAR_enable_cloudwatch_logs` and `TF_VAR_enable_cloudwatch_alarms`; explicit tfvars and command-line values take precedence over environment variables.

Output: `lambda_function_name`. When the log group is enabled, the output references the provisioned group so Lambda waits for log creation. Otherwise it returns `get-members` without indexing a missing resource. The existing Lambda function remains deployable independently of the alarms.

Changing a flag from `true` to `false` plans destruction of its managed resources, not just a pause in monitoring. Removing the managed log group deletes its retained logs. Disabling log-group deployment does not disable Lambda logging: the execution role still allows Lambda to recreate the log group automatically, potentially without the managed retention setting.

At the root, `enable_cloudwatch_alarms` also controls the entire SNS module. With alarms enabled, both alarms use `module.sns[0].topic_arn` for their notification actions. With alarms disabled, the SNS topic, policy, subscription, KMS key, and alias are not deployed, and the root `alarm_topic_arn` output is null. Disabling existing notifications plans their deletion; KMS key deletion is scheduled after its 30-day waiting period. The log-group flag remains independent.

Conditional resources use `[0]` addresses. Legacy unindexed address migration is not supported; review the plan before applying to a fresh deployment or an existing deployment already using these addresses.

With Terraform 1.7+, test all flag combinations from the infrastructure root:

```sh
terraform test -filter=tests/cloudwatch_deployment.tftest.hcl
```

AWS and archive providers are mocked; these tests do not deploy resources or create a Lambda ZIP.

Inherits the root AWS provider. Apply through the root module and preserve the existing state.