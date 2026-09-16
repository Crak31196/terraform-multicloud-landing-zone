# Azure WAF policy module (OWASP managed rule set by default).
#
# IMPORTANT: this module only defines the azurerm_web_application_firewall_policy
# resource. Attaching it to a real Application Gateway is client-specific (it depends
# on that client's existing Application Gateway SKU/topology -- WAF_v2 is required),
# so that wiring is intentionally left out of this reusable module. See
# docs/architecture.md and the comment block below for the attachment pattern.

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

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name_prefix}-${var.environment}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.mode
    file_upload_limit_in_mb     = var.file_upload_limit_mb
    request_body_check          = true
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = var.managed_rule_set_type
      version = var.managed_rule_set_version
    }
  }

  tags = local.tags
}

# --- Client-specific attachment pattern (documented, not applied here) --------
#
# Once a client has an Application Gateway (SKU: WAF_v2), point it at this policy:
#
#   resource "azurerm_application_gateway" "this" {
#     # ... gateway_ip_configuration, frontend/backend/listener/rule blocks ...
#     firewall_policy_id = module.waf.waf_policy_id
#     sku {
#       name = "WAF_v2"
#       tier = "WAF_v2"
#     }
#   }
#
# The Application Gateway topology (public vs. internal, listeners, backend pools)
# is specific to each client's application, so it is deliberately not templated here.
