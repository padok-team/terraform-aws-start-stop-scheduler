# Terraform Module AWS start_stop_scheduler

## General information

This module helps you shutdown AWS resources you don't use at night or during weekends to keep both your $ and CO² bills low!

It uses a _lambda_ function and a few _cronjobs_ to trigger a _start_ or _stop_ function at a given hour, on a subset of your AWS resources, selected by a _tag_.

It supports :

- **AutoscalingGroups**: it suspends the ASG and terminates its instances. At the start, it resumes the ASG, which launches new instances by itself.
- **EKS node groups**: if a node group is tagged, it will use the ASG handler for its underlying ASG.
- **RDS**: Run the function stop and start on them.
- **EC2 instances**: terminate instances. ⚠️ It does not start them back, as it is not stopped but terminated. Use with caution.

The lambda function is _idempotent_, so you can launch it on an already stopped/started resource without any risks! It simplifies your job when planning with crons.

![aws_schema](./docs/assets/aws_schema.png)

### Why not use AWS Instance Scheduler instead?

[AWS Instance Scheduler](https://github.com/aws-solutions/instance-scheduler-on-aws/tree/main) is the official AWS solution for this problem. It is a more complete solution, using a controlle approach: a lambda regularly checks the current time and decides to start or stop resources. It is therefore more resilient.

However it is also more complex and needs to be setup with CloudFormation.

A good rule of thumb to decide: if you have a few accounts and want to keep it simple, use this Terraform module. If you manage a multi-account cloud organization, check for the more complete and robust _Instance Scheduler_.

### About cronjobs

If you don't know much about crons, check <https://cron.help/>.

:warning: Beware, the AWS syntax is a bit special, check [their documentation](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-schedule-expressions.html#eb-cron-expressions) :

- It adds a 6th character for the year.
- You cannot set '\*' for both Day-of-week and Day-of-month

:alarm-clock: All the cronjobs expressions are in UTC time ! Check your current timezone and do the maths.

## Usage

This module can be installed using Padok's registry.

For example, if you want to shutdown during nights and weekends all staging resources :

- each night at 18:00 UTC (20:00 for France), stop resources with tag `Env=staging`
- each morning at 6:00 UTC (8:00 for France), stop resources with tag `Env=staging`

```hcl
module "aws_start_stop_scheduler" {
  source = "github.com/padok-team/terraform-aws-start-stop-scheduler"
  version = "v0.3.1"

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

  # to adjust if you have a lot of resources to manage
  # lamda_timeout = 600
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

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | A name used to create resources in module | `string` | n/a | yes |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | List of map containing, the following keys: name (for jobs name), start (cron for the start schedule), stop (cron for stop schedule), tag\_key and tag\_value (target recources) | <pre>list(object({<br>    name      = string<br>    start     = string<br>    stop      = string<br>    tag_key   = string<br>    tag_value = string<br>  }))</pre> | n/a | yes |
| <a name="input_asg_schedule"></a> [asg\_schedule](#input\_asg\_schedule) | Run the scheduler on AutoScalingGroup. | `bool` | `true` | no |
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | List of AWS region where the scheduler will be applied. By default target the current region. | `list(string)` | `null` | no |
| <a name="input_custom_iam_lambda_role"></a> [custom\_iam\_lambda\_role](#input\_custom\_iam\_lambda\_role) | Use a custom role used for the lambda. Useful if you cannot create IAM ressource directly with your AWS profile, or to share a role between several resources. | `bool` | `false` | no |
| <a name="input_custom_iam_lambda_role_arn"></a> [custom\_iam\_lambda\_role\_arn](#input\_custom\_iam\_lambda\_role\_arn) | Custom role arn used for the lambda. Used only if custom\_iam\_lambda\_role is set to true. | `string` | `null` | no |
| <a name="input_ec2_schedule"></a> [ec2\_schedule](#input\_ec2\_schedule) | Run the scheduler on EC2 instances. (only allows downscaling) | `bool` | `false` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Amount of time your Lambda Function has to run in seconds. | `number` | `120` | no |
| <a name="input_rds_schedule"></a> [rds\_schedule](#input\_rds\_schedule) | Run the scheduler on RDS. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_clouwatch_event_rules"></a> [clouwatch\_event\_rules](#output\_clouwatch\_event\_rules) | Cloudwatch event rules generated by the module to trigger the lambda |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | The ARN of the Lambda function |
| <a name="output_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#output\_lambda\_function\_invoke\_arn) | The ARN to be used for invoking Lambda function from API Gateway |
| <a name="output_lambda_function_last_modified"></a> [lambda\_function\_last\_modified](#output\_lambda\_function\_last\_modified) | The date Lambda function was last modified |
| <a name="output_lambda_function_log_group_arn"></a> [lambda\_function\_log\_group\_arn](#output\_lambda\_function\_log\_group\_arn) | The ARN of the lambda's log group |
| <a name="output_lambda_function_log_group_name"></a> [lambda\_function\_log\_group\_name](#output\_lambda\_function\_log\_group\_name) | The name of the lambda's log group |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | The name of the Lambda function |
| <a name="output_lambda_function_version"></a> [lambda\_function\_version](#output\_lambda\_function\_version) | Latest published version of your Lambda function |
| <a name="output_lambda_iam_role_arn"></a> [lambda\_iam\_role\_arn](#output\_lambda\_iam\_role\_arn) | The ARN of the IAM role used by Lambda function |
| <a name="output_lambda_iam_role_name"></a> [lambda\_iam\_role\_name](#output\_lambda\_iam\_role\_name) | The name of the IAM role used by Lambda function |

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

### Scale down an EKS cluster with Karpenter

If you are using Karpenter on its own node group, which then schedules the pods on EC2 instances, you should

1. First scale down the node group with Karpenter, to prevent it from scaling up new instances.
2. Then stop the EC2 instances.

When you scale up the node group, Karpenter will schedule the pods on the new instances. It will also cleanup _ghost_ Kubernetes nodes from the API server.

Here an example of how to do it :

```hcl
schedules = [
  {
    name      = "weekday_asg_working_hours",
    start     = "0 6 ? * MON-FRI *",
    stop      = "0 19 ? * MON-FRI *", # 19:00
    tag_key   = "scheduler",
    tag_value = "karpenter_node_group" # EKS node group hosting karpenter is tagged with this
  },
  {
    name      = "weekday_ec2_karpenter_working_hours",
    start     = "", # do not scale up
    stop      = "5 19 ? * MON-FRI *", # 19:05, 5 min after the ASG
    tag_key   = "scheduler",
    tag_value = "ec2_karpenter" # EC2 instances launched by Karpenter are tagged with this
  },
]

ec2_schedule = true # karpenter spawn raw EC2 instances
```

### Gracefully handle databases shutdown for applications

To avoid any issues with application lock in databases (for example migrations), you should shutdown databases after the application has been stopped. For this you may use two different schedules :

```hcl
 schedules = [
    {
      name      = "weekday_asg_working_hours",
      start     = "0 6 ? * MON-FRI *",
      stop      = "0 19 ? * MON-FRI *", # 30 min before the RDS
      tag_key   = "scheduler",
      tag_value = "asg"
    },
    {
      name      = "weekday_rds_working_hours",
      start     = "30 5 ? * MON-FRI *",
      stop      = "30 19 ? * MON-FRI *",
      tag_key   = "scheduler",
      tag_value = "rds"
    },
  ]
```

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

## License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
