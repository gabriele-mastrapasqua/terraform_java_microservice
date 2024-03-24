# Define the rate-based rule name
variable "rate_based_rule_name" {
  default = "BlockAfter10kRequestsPerDay"
}

# Define the maximum request limit (10,000 requests per day)
variable "max_requests_per_day" {
  default = 10000
}

resource "aws_wafv2_web_acl" "my_web_acl" {
  name        = "my-web-acl"
  description = "Web ACL for my application"
  scope = "REGIONAL"
  #capacity = 1

  default_action {
    allow {}
  }
  
  // Define your WAF rules and conditions here

# Define the rate-based rule
  rule {
    name     = var.rate_based_rule_name
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit = var.max_requests_per_day
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockedRequests"
      sampled_requests_enabled   = true
    }
  }


   // visibility config
   visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "waf-acl"
      sampled_requests_enabled   = false
    }

    tags = {
      Name = var.beanstalk_app_name
    }

}

# associate WAF with ALB balancer created from beanstalk
resource "aws_wafv2_web_acl_association" "my_acl_association" {
  resource_arn = aws_elastic_beanstalk_environment.beanstalk_env.load_balancers[0]
  web_acl_arn  = aws_wafv2_web_acl.my_web_acl.arn
}