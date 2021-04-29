# terraform {
#   required_version = ">= 0.15"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 3"
#     }
#   }
# }

# provider "aws" {
#   profile = "padok-lab"
#   region  = "eu-west-3"
# }

# module "main" {
#   source = "../.."
# }

# resource "test_assertions" "outputs" {
#   component = "outputs"
#   equal "output" {
#     description = "default output is /main.tf"
#     got         = module.main.main_tf.content
#     want        = file("${path.module}/symlink")
#   }
# }
