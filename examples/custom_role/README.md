Terrafom cannot install the module without the lambda's role arn, which itself is generated after Terraform installed it.

Therefore, for the first installation, you need to `target` the lambda role.

```bash
terraform apply --var-file $(terraform workspace show).tfvars -target=aws_iam_role.lambda
# Then
terraform apply --var-file $(terraform workspace show).tfvars
```
