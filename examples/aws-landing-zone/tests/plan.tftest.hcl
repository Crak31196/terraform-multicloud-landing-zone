# Integration-style native test for the AWS landing zone example: proves the root
# module wiring (vpc + kms + iam-baseline + budget-guardrail) plans cleanly end to
# end against a mocked provider, with no real AWS credentials required.
#
# Run with: (from examples/aws-landing-zone) terraform test

mock_provider "aws" {
  # See modules/aws/vpc/tests/vpc.tftest.hcl for why this override is necessary.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name_prefix          = "acme"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  break_glass_principal_arns = ["arn:aws:iam::123456789012:user/example-admin"]
  key_administrators         = ["arn:aws:iam::123456789012:user/example-admin"]
  monthly_budget_limit_usd   = 500
  budget_notification_emails = ["alerts@example.com"]
}

run "landing_zone_plans_cleanly" {
  # Every provider-computed ARN/ID (vpc id, kms arn, role arn, ...) stays unknown at
  # plan time, so this run only asserts on values whose cardinality/shape is known
  # from configuration -- the point of this test is that the whole example plans
  # cleanly with every module wired together, not any one module's internals
  # (those are covered by each module's own tests).
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "The example should wire through 2 public and 2 private subnets."
  }

  assert {
    condition     = output.budget_name == "acme-dev-monthly-cost-guardrail"
    error_message = "The example should expose the expected cost-guardrail budget name."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
