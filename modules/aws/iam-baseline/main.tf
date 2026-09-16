# AWS account governance baseline:
#   - account-wide password policy
#   - a break-glass emergency admin role (MFA-gated, tightly scoped principals)
#   - a least-privilege read-only auditor role
#   - AWS Config recorder + delivery channel + a couple of governance rules
#
# This mirrors the account-hygiene work a client needs on day one: nobody should be
# assuming AdministratorAccess directly, and drift/misconfiguration should be visible
# via Config rather than discovered during an incident.

locals {
  tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Password policy ---------------------------------------------------------

resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = var.password_policy.minimum_password_length
  require_lowercase_characters   = var.password_policy.require_lowercase_characters
  require_uppercase_characters   = var.password_policy.require_uppercase_characters
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change_password
  max_password_age               = var.password_policy.max_password_age
  password_reuse_prevention      = var.password_policy.password_reuse_prevention
}

# --- Break-glass emergency admin role ----------------------------------------

data "aws_iam_policy_document" "break_glass_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.break_glass_principal_arns
    }

    dynamic "condition" {
      for_each = var.require_mfa_for_break_glass ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

resource "aws_iam_role" "break_glass" {
  name                 = "${var.name_prefix}-${var.environment}-break-glass"
  description          = "Emergency-access admin role. Assumable only by pre-approved, MFA-authenticated principals."
  assume_role_policy   = data.aws_iam_policy_document.break_glass_assume.json
  max_session_duration = 3600

  tags = merge(local.tags, {
    Name    = "${var.name_prefix}-${var.environment}-break-glass"
    Purpose = "break-glass"
  })
}

resource "aws_iam_role_policy_attachment" "break_glass_admin" {
  role       = aws_iam_role.break_glass.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Least-privilege read-only auditor role ----------------------------------

data "aws_iam_policy_document" "readonly_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = length(var.readonly_principal_arns) > 0 ? var.readonly_principal_arns : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "readonly_auditor" {
  name               = "${var.name_prefix}-${var.environment}-readonly-auditor"
  description        = "Least-privilege role for auditors/CI: read-only visibility, no mutating permissions."
  assume_role_policy = data.aws_iam_policy_document.readonly_assume.json

  tags = merge(local.tags, {
    Name    = "${var.name_prefix}-${var.environment}-readonly-auditor"
    Purpose = "least-privilege-example"
  })
}

resource "aws_iam_role_policy_attachment" "readonly_auditor" {
  role       = aws_iam_role.readonly_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# --- AWS Config: recorder, delivery channel, governance rules ----------------

resource "aws_s3_bucket" "config" {
  count         = var.enable_config_recorder ? 1 : 0
  bucket        = "${var.name_prefix}-${var.environment}-aws-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.config_bucket_force_destroy

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-${var.environment}-aws-config"
  })
}

resource "aws_s3_bucket_public_access_block" "config" {
  count                   = var.enable_config_recorder ? 1 : 0
  bucket                  = aws_s3_bucket.config[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = var.enable_config_recorder ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "config_bucket_policy" {
  count = var.enable_config_recorder ? 1 : 0

  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config[0].arn]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.config[0].arn]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.enable_config_recorder ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  policy = data.aws_iam_policy_document.config_bucket_policy[0].json
}

data "aws_iam_policy_document" "config_assume" {
  count = var.enable_config_recorder ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count              = var.enable_config_recorder ? 1 : 0
  name               = "${var.name_prefix}-${var.environment}-aws-config-recorder"
  assume_role_policy = data.aws_iam_policy_document.config_assume[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config_recorder ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config_recorder ? 1 : 0
  name     = "${var.name_prefix}-${var.environment}-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config_recorder ? 1 : 0
  name           = "${var.name_prefix}-${var.environment}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config[0].bucket

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config_recorder ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "required_tags" {
  count = var.enable_config_recorder ? 1 : 0
  name  = "${var.name_prefix}-${var.environment}-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(
    zipmap(
      [for i, k in var.required_tag_keys : "tag${i + 1}Key"],
      var.required_tag_keys
    )
  )

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_config_rule" "s3_public_read_prohibited" {
  count = var.enable_config_recorder ? 1 : 0
  name  = "${var.name_prefix}-${var.environment}-s3-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.this]
}
