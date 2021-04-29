# Terraform Module AWS start_stop_scheduler

## Compatibility

This module is meant for use with Terraform >= 0.12.6.

## Requirements

* [terraform-docs](https://github.com/terraform-docs/terraform-docs)
* [pre-commit](https://pre-commit.com/)

## Contributing

Refer to the [contribution guidelines](./CONTRIBUTING.md) for
information on contributing to this module.

## Usage

This module can be installed using Padok's registry:

```hcl
module "aws_start_stop_scheduler" {
  source = "terraform-registry.playground.padok.cloud/incubator/start_stop_scheduler/aws"
  version = "vX.Y.Z"
  # ... other module's arguments
}
```

<!-- BEGIN_TF_DOCS -->
The template can be customized with aribitrary markdown content.
For example this can be shown before the actual content generated
by formatters.



## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3 |

## Inputs

No inputs.

## Outputs

No outputs.


You can also show something after it!
<!-- END_TF_DOCS -->

## File structure

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
