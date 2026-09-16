# Cost guardrail: an AWS Budget with multi-threshold alerts fanned out over SNS/email.
#
# This is the reusable version of a real recurring finding: unused NAT gateways, idle
# load balancers and orphaned AMIs quietly running up the bill until someone notices
# the invoice. A budget alert does not remove the waste automatically, but it turns
# "nobody noticed for three months" into "the team got an email at 50% of budget".

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

resource "aws_sns_topic" "budget_alerts" {
  name = "${var.name_prefix}-${var.environment}-budget-alerts"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "budget_alert_emails" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_budgets_budget" "monthly_cost_guardrail" {
  name         = "${var.name_prefix}-${var.environment}-monthly-cost-guardrail"
  budget_type  = "COST"
  limit_amount = format("%.2f", var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.alert_thresholds_percent
    content {
      comparison_operator       = "GREATER_THAN"
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_sns_topic_arns = [aws_sns_topic.budget_alerts.arn]
    }
  }
}
