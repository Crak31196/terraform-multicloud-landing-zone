# Tests

This repo uses Terraform's native testing framework (`*.tftest.hcl`, `terraform test`).
Terraform requires test files to live alongside the configuration they exercise, so
tests are colocated per module/example rather than in one shared directory:

| Test file | Exercises |
|---|---|
| `modules/aws/vpc/tests/vpc.tftest.hcl` | AWS VPC module |
| `modules/aws/kms/tests/kms.tftest.hcl` | AWS KMS module |
| `modules/azure/vnet/tests/vnet.tftest.hcl` | Azure VNet module |
| `modules/azure/keyvault/tests/keyvault.tftest.hcl` | Azure Key Vault module |
| `examples/aws-landing-zone/tests/plan.tftest.hcl` | Full AWS landing zone wiring |
| `examples/azure-landing-zone/tests/plan.tftest.hcl` | Full Azure landing zone wiring |

Every test file uses `mock_provider "aws" {}` / `mock_provider "azurerm" {}`, so
`terraform test` runs completely offline against a simulated provider -- no AWS/Azure
credentials, accounts or network access are required, and nothing is ever actually
created.

Run all of them:

```bash
for d in modules/aws/vpc modules/aws/kms modules/azure/vnet modules/azure/keyvault \
         examples/aws-landing-zone examples/azure-landing-zone; do
  (cd "$d" && terraform init -backend=false -input=false && terraform test)
done
```

See the root [README.md](../README.md#running-tests) for the exact per-directory
commands, and `.github/workflows/ci.yml` for how this is wired into CI.
