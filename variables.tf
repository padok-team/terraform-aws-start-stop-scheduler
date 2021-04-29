variable "my_var" {
  type        = string
  description = "A variable with a default value and a condition."
  default     = "toto!"

  validation {
    condition     = length(var.my_var) > 4
    error_message = "This variable should have more than 4 characters."
  }
}

variable "another_var" {
  type        = string
  description = "A variable with a condition."

  validation {
    condition     = length(var.another_var) > 6
    error_message = "This variable should have more than 6 characters."
  }
}
