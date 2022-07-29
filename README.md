# Terraform Module AWS start_stop_scheduler

## General information

This module helps you shutdown AWS resources you don't use at night or during weekends to keep both your $ and CO² bills low!

It uses a _lambda_ function and a few _cronjobs_ to trigger a _start_ or _stop_ function at a given hour, on a subset of your AWS resources, selected by a _tag_.

It supports :

- **AutoscalingGroups**: it suspends the ASG and terminates its instances. At the start, it resumes the ASG, which launches new instances by itself.
- RDS: support simple RDS DB instance. Run the function stop and start on them.
- ~~EC2 instances~~: maybe

The lambda function is _idempotent_, so you can launch it on an already stopped/started resource without any risks! It simplifies your job when planning with crons.

![aws_schema](./docs/assets/aws_schema.png)

### About cronjobs

If you don't know much about crons, check <https://cron.help/>.

:warning: Beware, the AWS syntax is a bit special, check [their documentation](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-schedule-expressions.html#eb-cron-expressions) :

- It adds a 6th character for the year.
- You cannot set '\*' for both Day-of-week and Day-of-month

:alarm-clock: All the cronjobs expressions are in UTC time ! Check your current timezone and do the maths.

## Compatibility

This module is meant for use with Terraform >= 0.13 and `aws` provider >= 2.

## Usage

This module can be installed using Padok's registry.

For example, if you want to shutdown during nights and weekends all staging resources :

- each night at 18:00 UTC (20:00 for France), stop resources with tag `Env=staging`
- each morning at 6:00 UTC (8:00 for France), stop resources with tag `Env=staging`

```hcl
module "aws_start_stop_scheduler" {
  source = "terraform-registry.playground.padok.cloud/incubator/start_stop_scheduler/aws"
  version = "v0.5.0"

  name = "start_stop_scheduler"
  schedules = [
    {
      name      = "weekday_working_hours",
      start     = "0 6 ? * MON-FRI *",
      stop      = "0 18 ? * MON-FRI *",
      tag_key   = "Env",
      tag_value = "staging",
    }
  ]
}
```

_You can choose to only start or stop a set of resources by omitting start or stop._ For example, here a valid conf :

```hcl
schedules = [
    {
      name      = "stop_at_night",
      start     = "",
      stop      = "0 18 ? * MON-FRI *",
      tag_key   = "Env",
      tag_value = "sandbox",
    }
  ]
```

_You may also set up several schedule in the same module. The **name** parameter must be unique between schedules._

```hcl
schedules = [
    {
      name      = "weekday_working_hours",
      start     = "0 6 ? * MON-FRI *",
      stop      = "0 18 ? * MON-FRI *",
      tag_key   = "Env",
      tag_value = "staging",
    },
    {
      name      = "stop_at_night",
      start     = "",
      stop      = "0 18 ? * MON-FRI *",
      tag_key   = "Env",
      tag_value = "sandbox",
    }
  ]
```

You can check at [`examples/asg`](./examples/asg) for a complete example with AutoScalingGroups, and [`examples/rds`](./examples/asg) for RDS.

You can also test the deployed lambda function with arbitrary arguments :

```bash
aws lambda invoke --function-name <function_name_from_output> --payload '{"action": "start", "tag": {"key": "Env", "value": "staging"}}' --cli-binary-format raw-in-base64-out out.txt
```

<!-- BEGIN_TF_DOCS -->

## Providers

| Name                                                         | Version |
| ------------------------------------------------------------ | ------- |
| <a name="provider_archive"></a> [archive](#provider_archive) | >= 2    |
| <a name="provider_aws"></a> [aws](#provider_aws)             | >= 3    |

## Inputs

| Name                                                                                                            | Description                                                                                                                                                                    | Type                                                                                                                                | Default | Required |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | ------- | :------: |
| <a name="input_name"></a> [name](#input_name)                                                                   | A name used to create resources in module                                                                                                                                      | `string`                                                                                                                            | n/a     |   yes    |
| <a name="input_schedules"></a> [schedules](#input_schedules)                                                    | List of map containing, the following keys: name (for jobs name), start (cron for the start schedule), stop (cron for stop schedule), tag_key and tag_value (target recources) | <pre>list(object({<br> name = string<br> start = string<br> stop = string<br> tag_key = string<br> tag_value = string<br> }))</pre> | n/a     |   yes    |
| <a name="input_asg_schedule"></a> [asg_schedule](#input_asg_schedule)                                           | Run the scheduler on AutoScalingGroup.                                                                                                                                         | `bool`                                                                                                                              | `true`  |    no    |
| <a name="input_aws_regions"></a> [aws_regions](#input_aws_regions)                                              | List of AWS region where the scheduler will be applied. By default target the current region.                                                                                  | `list(string)`                                                                                                                      | `null`  |    no    |
| <a name="input_custom_iam_lambda_role"></a> [custom_iam_lambda_role](#input_custom_iam_lambda_role)             | Use a custom role used for the lambda. Useful if you cannot create IAM ressource directly with your AWS profile, or to share a role between several resources.                 | `bool`                                                                                                                              | `false` |    no    |
| <a name="input_custom_iam_lambda_role_arn"></a> [custom_iam_lambda_role_arn](#input_custom_iam_lambda_role_arn) | Custom role arn used for the lambda. Used only if custom_iam_lambda_role is set to true.                                                                                       | `string`                                                                                                                            | `null`  |    no    |
| <a name="input_lambda_timeout"></a> [lambda_timeout](#input_lambda_timeout)                                     | Amount of time your Lambda Function has to run in seconds.                                                                                                                     | `number`                                                                                                                            | `10`    |    no    |
| <a name="input_rds_schedule"></a> [rds_schedule](#input_rds_schedule)                                           | Run the scheduler on RDS.                                                                                                                                                      | `bool`                                                                                                                              | `true`  |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                   | Custom Resource tags                                                                                                                                                           | `map(string)`                                                                                                                       | `{}`    |    no    |

## Outputs

| Name                                                                                                                          | Description                                                          |
| ----------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| <a name="output_clouwatch_event_rules"></a> [clouwatch_event_rules](#output_clouwatch_event_rules)                            | Cloudwatch event rules generated by the module to trigger the lambda |
| <a name="output_lambda_function_arn"></a> [lambda_function_arn](#output_lambda_function_arn)                                  | The ARN of the Lambda function                                       |
| <a name="output_lambda_function_invoke_arn"></a> [lambda_function_invoke_arn](#output_lambda_function_invoke_arn)             | The ARN to be used for invoking Lambda function from API Gateway     |
| <a name="output_lambda_function_last_modified"></a> [lambda_function_last_modified](#output_lambda_function_last_modified)    | The date Lambda function was last modified                           |
| <a name="output_lambda_function_log_group_arn"></a> [lambda_function_log_group_arn](#output_lambda_function_log_group_arn)    | The ARN of the lambda's log group                                    |
| <a name="output_lambda_function_log_group_name"></a> [lambda_function_log_group_name](#output_lambda_function_log_group_name) | The name of the lambda's log group                                   |
| <a name="output_lambda_function_name"></a> [lambda_function_name](#output_lambda_function_name)                               | The name of the Lambda function                                      |
| <a name="output_lambda_function_version"></a> [lambda_function_version](#output_lambda_function_version)                      | Latest published version of your Lambda function                     |
| <a name="output_lambda_iam_role_arn"></a> [lambda_iam_role_arn](#output_lambda_iam_role_arn)                                  | The ARN of the IAM role used by Lambda function                      |
| <a name="output_lambda_iam_role_name"></a> [lambda_iam_role_name](#output_lambda_iam_role_name)                               | The name of the IAM role used by Lambda function                     |

<!-- END_TF_DOCS -->

## Advanced features

### Custom role

In some cases, you might not be able to create IAM resources with the same role used to create the lambda function, or you might want to share a common role between several modules. In that case, you can provide a _custom iam role_ to the module, which will be used instead of the one created inside the module.

In that case you need to set both variables `custom_iam_lambda_role` and `custom_iam_lambda_role_arn`.

```hcl
module "aws_start_stop_scheduler" {
  ...

  custom_iam_lambda_role = true
  custom_iam_lambda_role_arn = aws_iam_role.lambda.arn
}
```

You have a full working example in [examples/custom_role](./examples/custom_role).

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

**Please open GitLab issues for any problems encoutered when using the module, or suggestions !**

You can find the initial draft document [here](https://www.notion.so/m33/Extinction-des-machines-hors-prod-la-nuit-et-weekend-20398489023d4fa9ba847b84efe44d79).

### Requirements

- [terraform-docs](https://github.com/terraform-docs/terraform-docs)
- [pre-commit](https://pre-commit.com/)

### File structure

The project has the following folders and files:

- /: root folder
- /examples: examples for using this module
- /scripts: Scripts for specific tasks on module (see Infrastructure section on this file)
- /test: Folders with files for testing the module (see Testing section on this file)
- /helpers: Optional helper scripts for ease of use
- /main.tf: main file for this module, contains all the resources to create
- /variables.tf: all the variables for the module
- /output.tf: the outputs of the module
- /README.md: this file
