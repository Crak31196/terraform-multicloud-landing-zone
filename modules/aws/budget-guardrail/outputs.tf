output "budget_name" {
  description = "Name of the AWS Budget guardrail."
  value       = aws_budgets_budget.monthly_cost_guardrail.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic that receives budget-threshold alerts."
  value       = aws_sns_topic.budget_alerts.arn
}

output "alert_thresholds_percent" {
  description = "Percent-of-budget thresholds configured to trigger an alert."
  value       = var.alert_thresholds_percent
}
