# Screenshots

Screenshots pending -- this repo ships infrastructure-as-code, not a UI, so the most
useful screenshots here are terminal output proving the toolkit works end to end:

- `terraform validate` passing across every module/example
- `terraform test` output showing the mocked-provider test suites passing
- `terraform plan` output for `examples/aws-landing-zone` and
  `examples/azure-landing-zone` against a real (sandbox) account
- The AWS Cost Explorer / Azure Cost Management view after the budget-guardrail
  module has been running for a billing cycle (demo/illustrative)

These will be added once this toolkit has run against a real sandbox account.
