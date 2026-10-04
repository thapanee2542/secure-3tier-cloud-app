# AWS Infrastructure

The Terraform root module for the Secure 3-Tier Cloud App. It provisions a private S3 frontend served through CloudFront, a public API Gateway route backed by Lambda, private networking, DynamoDB member records, and CloudWatch alarms with SNS email notifications.

The organization follows the [AWS Terraform best-practice guidance](https://github.com/aws-samples/aws-terraform-best-practices), using a flat set of local service modules. The root composes the modules, configures the AWS provider, and owns the single deployment state. Service folders expose typed inputs and resource-backed outputs so security policies and dependencies are easy to inspect.

## Layout

```text
infrastructure/
|-- main.tf                  # Wires the AWS service modules together
|-- locals.tf                # Shared expressions and demo member data
|-- variables.tf             # Typed deployment inputs
|-- outputs.tf               # Deployment URLs and resource identifiers
|-- providers.tf             # Root AWS provider and default tags
|-- versions.tf              # Terraform and provider requirements
|-- terraform.tfvars.example # Safe configuration template
|-- .terraform.lock.hcl      # Provider selections; commit this file
|-- modules/
|   |-- vpc/                 # VPC, private subnets, routing, security group, endpoint
|   |-- dynamodb/            # Members table and demo records
|   |-- iam/                 # Lambda execution role and scoped policies
|   |-- lambda/              # Single-file packaging and private-subnet function
|   |-- api_gateway/         # REST API, throttling, and scoped invocation permission
|   |-- s3/                  # Private bucket, encryption, objects, and access policy
|   |-- cloudfront/          # HTTPS delivery and S3 OAC
|   |-- cloudwatch/          # Lambda log group and API alarms
|   `-- sns/                 # Alarm publishing policy and email subscription
|-- tests/
|   `-- security.tftest.hcl  # Offline mocked plans and security assertions
|-- files/
|   `-- images/              # Member photos uploaded to S3
`-- dist/                    # Generated frontend staging directory; ignored
```

Each service folder has `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`. Open the folder for the AWS service you want to change. Do not run deployment commands inside individual module folders: they are components of the root, not independent environments. Static member photos live under `files/`; generated frontend files remain in `dist/` so the build workflow is unchanged.

## Security Boundaries

- [modules/vpc](modules/vpc/README.md) owns private subnet routing and DynamoDB-only HTTPS egress. Its endpoint policy restricts the table and execution role.
- [modules/iam](modules/iam/README.md) owns the table-scoped `dynamodb:Scan` permission and Lambda execution policies.
- [modules/s3](modules/s3/README.md) owns encryption, public-access blocking, and the policy granting reads only to the specified CloudFront distribution while denying insecure transport.
- [modules/cloudfront](modules/cloudfront/README.md) owns HTTPS delivery and signed S3 origin access.
- [modules/api_gateway](modules/api_gateway/README.md) owns throttling and stage/route-scoped Lambda invocation. The endpoint remains public without authentication; this refactor does not make member data private.
- [modules/cloudwatch](modules/cloudwatch/README.md) and [modules/sns](modules/sns/README.md) own monitoring, log retention, and source-restricted notifications.

Child modules inherit the root provider and default tags. Paths to the handler, images, and frontend build are passed from the root rather than resolved relative to child folders. Granular IAM and log-group outputs preserve creation order without cyclic whole-module dependencies.

The Lambda archive includes only [../backend/get_members.py](../backend/get_members.py). Backend tests, Python tooling, and virtual environments are not packaged.

## Setup

Use Terraform `>= 1.5.0, < 2.0.0` and an authenticated AWS profile. From this directory, copy the safe template if no local configuration exists:

```sh
test -f terraform.tfvars || cp terraform.tfvars.example terraform.tfvars
```

Set your AWS profile, deployment identifiers, and notification email in `terraform.tfvars`. The real tfvars file is ignored by Git. Existing deployments must keep their current inputs and state.

Build and stage frontend files from the repository root using the steps in [../README.md](../README.md). Terraform reads this directory's `dist/`, not the separate sibling repository used by the frontend postbuild script.

## Checks and Deployment

From the repository root, use [../tasks](../tasks):

```sh
./tasks init
./tasks fmt-check
./tasks validate
./tasks plan -out=deploy.tfplan
./tasks apply deploy.tfplan
```

`./tasks fmt` applies recursive formatting and `./tasks destroy` deletes the stack using Terraform's normal confirmation behavior. The explicit `terraform-*` names work too. Commands use this directory through `-chdir`; relative plan files and `-var-file` arguments are resolved here. No automatic approval is added, but applying an already saved plan does not prompt again. Review it before applying.

From this directory:

```sh
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=deploy.tfplan
```

Review the saved plan before deployment, then run:

```sh
terraform apply deploy.tfplan
```

Use `terraform fmt -recursive` to apply formatting. Validation checks the module without deploying AWS resources. Confirm the SNS email subscription after the first deployment.

## Offline Tests

Mocked provider tests require Terraform 1.7 or newer. From this directory:

```sh
terraform init
terraform test -filter=tests/security.tftest.hcl
```

The five test runs plan the root graph and check S3 protections, private subnets, endpoint policy scope, IAM scan permissions, and DynamoDB encryption/recovery. Both AWS and archive providers are mocked: tests do not call AWS, create a ZIP, or update deployment state. Provider installation during init may require network access.

## Inputs

| Name | Type | Default | Purpose |
| --- | --- | --- | --- |
| `aws_profile` | string | `personal` | AWS CLI profile for the provider. |
| `aws_region` | string | `ap-southeast-7` | Deployment region. |
| `project_name` | string | `secure-3tier-infrastructure` | Project tag and supported resource name prefix. |
| `environment` | string | `dev` | Environment tag and supported resource name prefix. |
| `api_stage_name` | string | `dev` | API Gateway stage and scoped Lambda permission. |
| `notification_email` | string | Required | SNS alarm subscription email. |
| `enable_cloudwatch_logs` | bool | `true` | Deploy and manage the Lambda log group. |
| `enable_cloudwatch_alarms` | bool | `true` | Deploy both API metric alarms and their SNS/KMS notifications. |

Defaults are retained for compatibility. Set explicit deployment values in tfvars rather than depending on defaults for multiple environments. Some AWS resource names are fixed; changing only the environment input does not provide independent deployments in the same account and region.

CloudWatch deployment can be configured separately for each environment through these two flags. For example, set `enable_cloudwatch_logs = true` and `enable_cloudwatch_alarms = false` in your local tfvars to keep logs without deploying alarms. Alternatively, use `TF_VAR_enable_cloudwatch_logs` and `TF_VAR_enable_cloudwatch_alarms` when the flags are not set in tfvars; tfvars values take precedence over environment variables.

Setting a previously enabled flag to `false` plans resource deletion. Deleting a managed log group removes its retained logs and does not prevent Lambda from recreating the group automatically. The alarm flag also controls the SNS module: enabling alarms wires `module.sns[0].topic_arn` to both alarms; disabling alarms removes the topic, policy, subscription, key, and alias, with KMS deletion scheduled after 30 days. The root `alarm_topic_arn` output becomes null while notifications are disabled. See [modules/cloudwatch/README.md](modules/cloudwatch/README.md) for flag combinations, migration behavior, and mocked tests.

## Outputs

| Name | Purpose |
| --- | --- |
| `cloudfront_base_url` | HTTPS frontend URL. |
| `members_api_url` | Direct public API URL. |
| `frontend_bucket_name` | Private frontend and image bucket. |
| `alarm_topic_arn` | SNS notification topic ARN. |
| `vpc_id` | VPC identifier. |
| `private_route_table_id` | Shared private route table identifier. |
| `private_subnet_a_id` | First private subnet identifier. |
| `private_subnet_a_availability_zone` | First subnet's Availability Zone. |
| `private_subnet_b_id` | Second private subnet identifier. |
| `private_subnet_b_availability_zone` | Second subnet's Availability Zone. |
| `dynamodb_vpc_endpoint_id` | DynamoDB Gateway endpoint identifier. |
| `dynamodb_prefix_list_id` | DynamoDB managed prefix list identifier. |
| `lambda_execution_role_arn` | Lambda execution role ARN. |

## State and Compatibility

Resource addresses use service module prefixes, such as `module.vpc.aws_vpc.main`, with conditional resources using `[0]` indexes. Legacy address migration blocks have been removed because this configuration is intended for a fresh deployment after the previous stack has been destroyed.

State remains local for this existing deployment. Keep `terraform.tfstate` and its backup protected and out of Git. Do not delete state, initialize a new workspace, run `terraform state mv` manually, or apply a module folder separately.

Before deploying, run `terraform init`, create a saved plan, and confirm that it matches the intended fresh stack. Stop if resources are unexpectedly destroyed or replaced. Offline mock tests verify wiring and security assertions, not the contents of the real AWS account.

If legacy AWS resources or state entries remain, resolve them before applying; this configuration no longer migrates their addresses automatically. Confirm the selected backend and workspace, and do not restore an old state backup merely to reuse this layout. Keep existing state files intact until the intended deployment is verified.

For collaboration or CI, configure an encrypted remote state backend with locking in a separately reviewed migration. Choose the state bucket, access policy, and locking mechanism before using `terraform init -migrate-state`; do not apply an empty remote backend against existing resources. Keep credentials outside Terraform configuration.

Commit `.terraform.lock.hcl` to reproduce provider selections. Run `terraform init -upgrade` only when intentionally updating providers. This module pins provider compatibility ranges but does not add remote modules or change provider versions during the refactor.