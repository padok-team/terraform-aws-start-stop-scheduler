variable "name" {
  description = "A name used to create resources in module"
  type        = string
  validation {
    condition     = length(var.name) > 1
    error_message = "This variable should have more than 1 characters."
  }
}

variable "schedules" {
  type = list(object({
    name      = string
    start     = string
    stop      = string
    tag_key   = string
    tag_value = string
  }))
  description = "List of map containing, the following keys: name (for jobs name), start (cron for the start schedule), stop (cron for stop schedule), tag_key and tag_value (target recources)"
}

variable "tags" {
  default     = {}
  description = "Custom Resource tags"
  type        = map(string)
}

variable "lambda_timeout" {
  default     = 120
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

variable "ec2_schedule" {
  default     = false
  description = "Run the scheduler on EC2 instances. (only allows downscaling)"
  type        = bool
}

variable "aws_regions" {
  default     = null
  description = "List of AWS region where the scheduler will be applied. By default target the current region."
  type        = list(string)
}

variable "custom_iam_lambda_role" {
  default     = false
  description = "Use a custom role used for the lambda. Useful if you cannot create IAM ressource directly with your AWS profile, or to share a role between several resources."
  type        = bool
}

variable "custom_iam_lambda_role_arn" {
  default     = null
  description = "Custom role arn used for the lambda. Used only if custom_iam_lambda_role is set to true."
  type        = string
}
