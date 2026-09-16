# Native Terraform tests for the AWS VPC module, run entirely against a mocked
# provider -- no AWS credentials or network access required.
#
# Run with: (from modules/aws/vpc) terraform test

mock_provider "aws" {
  # aws_iam_policy_document is normally computed locally (no API call), but under a
  # fully mocked provider its "json" output would otherwise be an arbitrary mock
  # string, which fails aws_iam_role's plan-time JSON-policy validation. Give it a
  # fixed, valid policy document so downstream resources see well-formed JSON.
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
}

run "creates_one_subnet_per_az" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Expected one public subnet per availability zone."
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Expected one private subnet per availability zone."
  }
}

run "single_nat_gateway_is_the_cost_guardrail_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway defaults to true, so exactly one NAT Gateway should be planned."
  }

  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "A single shared private route table is expected when single_nat_gateway is true."
  }
}

run "one_nat_gateway_per_az_when_disabled" {
  command = plan

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Disabling single_nat_gateway should provision one NAT Gateway per availability zone."
  }
}

run "flow_logs_enabled_by_default" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "enable_flow_logs defaults to true, so a flow log resource should be planned."
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days == 30
    error_message = "Default flow log retention should be 30 days."
  }
}

run "flow_logs_can_be_disabled" {
  command = plan

  variables {
    enable_flow_logs = false
  }

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "No flow log resources should be planned when enable_flow_logs is false."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}

run "rejects_malformed_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "not-a-cidr"
  }

  expect_failures = [var.vpc_cidr]
}

run "rejects_single_availability_zone" {
  command = plan

  variables {
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}
