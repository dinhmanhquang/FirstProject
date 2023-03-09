module "waf" {
  version =  "~> 3.8.1"
  source  = "umotif-public/waf-webaclv2/aws"

  scope                        = "REGIONAL"
  name_prefix                  = "${var.name}_waf"
  alb_arn                      = var.alb_arn
  create_alb_association       = true
  allow_default_action         = true
  create_logging_configuration = true
  log_destination_configs      = ["${var.aws_cloudwatch_log_group_arn}"]

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}_main_metrics"
    sampled_requests_enabled   = true
  }

  rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = "1"
      override_action = "none"

      visibility_config = {
        metric_name = "AWSManagedRulesCommonRuleSet"
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        excluded_rule = [
          "SizeRestrictions_QUERYSTRING",
          "SizeRestrictions_BODY",
          "GenericRFI_QUERYARGUMENTS",
          "GenericRFI_BODY",
          "CrossSiteScripting_BODY"
        ]
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = "2"

      override_action = "count"

      visibility_config = {
        metric_name = "AWSManagedRulesKnownBadInputsRuleSet"
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = "3"

      override_action = "none"

      visibility_config = {
        metric_name = "AWSManagedRulesSQLiRuleSet"
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    },
  ]

  tags = {
    "Name" = "${var.name}_waf"
    "Env"  = "terraform"
  }
}
