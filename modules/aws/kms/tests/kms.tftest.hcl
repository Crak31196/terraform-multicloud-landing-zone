# Native Terraform tests for the AWS KMS module, run entirely against a mocked
# provider -- no AWS credentials or network access required.
#
# Run with: (from modules/aws/kms) terraform test

mock_provider "aws" {
  # See modules/aws/vpc/tests/vpc.tftest.hcl for why this override is necessary:
  # aws_iam_policy_document's "json" attribute must be valid JSON for aws_kms_key's
  # plan-time policy validation to succeed under a fully mocked provider.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name_prefix        = "acme"
  environment        = "dev"
  key_administrators = ["arn:aws:iam::123456789012:role/example-admin"]
}

run "rotation_enabled_by_default" {
  command = plan

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == true
    error_message = "enable_key_rotation should default to true for a secure-by-default key."
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "deletion_window_in_days should default to 30."
  }
}

run "creates_expected_alias" {
  command = plan

  assert {
    condition     = aws_kms_alias.this.name == "alias/acme-dev"
    error_message = "Alias should follow the <name_prefix>-<environment> naming convention."
  }
}

run "rotation_can_be_disabled" {
  command = plan

  variables {
    enable_key_rotation = false
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == false
    error_message = "enable_key_rotation should be settable to false."
  }
}

run "rejects_deletion_window_below_minimum" {
  command = plan

  variables {
    deletion_window_in_days = 3
  }

  expect_failures = [var.deletion_window_in_days]
}

run "rejects_deletion_window_above_maximum" {
  command = plan

  variables {
    deletion_window_in_days = 45
  }

  expect_failures = [var.deletion_window_in_days]
}

run "rejects_empty_key_administrators" {
  command = plan

  variables {
    key_administrators = []
  }

  expect_failures = [var.key_administrators]
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
