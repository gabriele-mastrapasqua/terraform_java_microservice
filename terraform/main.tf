resource "aws_security_group" "beanstalk_sg" {
  name        = "beanstalk-sg"
  description = "Security group for Elastic Beanstalk environment"

  // Allow inbound traffic on port 80 for web traffic (adjust as needed)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow outbound traffic to RDS instance on default port 3306
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.rds_sg.id]
  }

}

###
###
###

resource "aws_elastic_beanstalk_application" "my_app" {
  name = var.beanstalk_app_name
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = var.beanstalk_app_version
  application = aws_elastic_beanstalk_application.my_app.name
  description = "My Java micro application version 1"
  bucket      = "my-bucket"            # Replace with your S3 bucket name
  key         = "path/to/your/app.jar" # Replace with your app JAR file path in S3
}


resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name        = var.beanstalk_env_name
  application = aws_elastic_beanstalk_application.my_app.name
  #solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Docker 19.03.13-ce"
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Corretto 17"


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.ec2_instance_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  // Attach the security group to the Elastic Beanstalk environment
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"          # Optional: Specify the server port if needed
    value     = var.beanstalk_app_port # Example port number
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST" # Custom environment variable for RDS endpoint
    value     = aws_db_instance.db_instance.endpoint
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME" # Custom environment variable for DB name
    value     = aws_db_instance.db_instance.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER" # Custom environment variable for DB user
    value     = aws_db_instance.db_instance.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD" # Custom environment variable for DB password
    value     = aws_db_instance.db_instance.password
  }


  // Deploy the application version
  depends_on = [aws_elastic_beanstalk_application_version.app_version]


}


resource "aws_autoscaling_group" "beanstalk_asg" {
  launch_configuration = aws_elastic_beanstalk_environment.beanstalk_env.name

  min_size         = 1
  max_size         = var.ec2_scaling_max # 1 default ondemand instance; 3 max if scaling
  desired_capacity = var.ec2_scaling_desired

  tag {
    key                 = "Name"
    value               = "beanstalk-app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "webserver"
    propagate_at_launch = true
  }

  target_group_arns = [aws_elastic_beanstalk_environment.beanstalk_env.arn]

  termination_policies = ["OldestInstance"]

}

resource "aws_autoscaling_policy" "scale_policy" {
  name                   = "scale-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.beanstalk_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-utilization-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when CPU utilization exceeds 70% for 2 periods"
  alarm_actions       = [aws_autoscaling_policy.scale_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.beanstalk_asg.name
  }
}
