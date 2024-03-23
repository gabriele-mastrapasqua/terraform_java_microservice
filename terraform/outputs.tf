
output "beanstalk_elb_endpoint" {
  value = aws_elastic_beanstalk_environment.beanstalk_env.endpoint_url
}

output "beanstalk_env_arn" {
  value = aws_elastic_beanstalk_environment.beanstalk_env.arn
}

output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.beanstalk_env.name
}

output "beanstalk_app_name" {
  value = aws_elastic_beanstalk_application.my_app.name
}

output "rds_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}

output "rds_username" {
  value     = aws_db_instance.db_instance.username
  sensitive = true
}

output "rds_password" {
  value     = aws_db_instance.db_instance.password
  sensitive = true
}
