resource "aws_wafv2_web_acl" "my_web_acl" {
  name        = "my-web-acl"
  description = "Web ACL for my application"
  scope = "REGIONAL"
  #capacity = 1

  default_action {
    allow {}
  }
  
  // Define your WAF rules and conditions here


   // visibility config
   visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rule-1"
      sampled_requests_enabled   = false
    }

    tags = {
      Name = var.beanstalk_app_name
    }

}

#resource "aws_wafv2_web_acl_association" "my_acl_association" {
#  resource_arn = aws_elastic_beanstalk_environment.beanstalk_env.load_balancers[0].arn
#  web_acl_arn  = aws_wafv2_web_acl.my_web_acl.arn
#}