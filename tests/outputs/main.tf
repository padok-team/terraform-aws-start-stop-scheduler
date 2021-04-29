terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

module "main" {
  source = "../.."

  another_var = "i am toto!"
}

resource "test_assertions" "outputs" {
  component = "outputs"
  equal "output" {
    description = "default output is /main.tf"
    got         = module.main.main_tf.content
    want        = file("${path.module}/symlink")
  }
}
