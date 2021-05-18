variable "name" {
  description = "A name used to create resources in module"
  type        = string
  validation {
    condition     = length(var.name) > 1
    error_message = "This variable should have more than 1 characters."
  }
}

variable "schedules" {
  description = "The configuration of your crons. Select your resources with tags, and specify several crons for start and stop."
  type        = list(map(map(string)))

  # TODO validation
}

variable "tags" {
  default     = {}
  description = "Custom Resource tags"
  type        = map(string)
}

variable "lambda_timeout" {
  default     = 10
  description = "Amount of time your Lambda Function has to run in seconds."
  type        = number

  validation {
    condition     = var.lambda_timeout < 900
    error_message = "AWS Lambda Quota limits lambda execution to 15 min."
  }
}

variable "rds_schedule" {
  default     = true
  description = "Run the scheduler on RDS."
  type        = bool
}

variable "asg_schedule" {
  default     = true
  description = "Run the scheduler on AutoScalingGroup."
  type        = bool
}

variable "aws_regions" {
  default     = null
  description = "List of AWS region where the scheduler will be applied. By default target the current region."
  type        = list(string)
}

variable "custom_iam_lambda_role_arn" {
  default     = null
  description = "Custom role used for the lambda. Useful if you cannot create IAM ressource directly with your AWS profile, or to share a role between several resources."
  type        = string
}
