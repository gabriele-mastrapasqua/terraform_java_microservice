provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

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

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"

  // Allow inbound traffic from Elastic Beanstalk security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    #security_groups = [aws_security_group.beanstalk_sg.id]
  }

  // Allow outbound traffic to Elastic Beanstalk security group on port 80
  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    #security_groups = [aws_security_group.beanstalk_sg.id]
  }
}

###
###
###

resource "aws_elastic_beanstalk_application" "my_app" {
  name = "my-beanstalk-app"
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.my_app.name
  description = "My Java application version 1"
  bucket      = "my-bucket"            # Replace with your S3 bucket name
  key         = "path/to/your/app.jar" # Replace with your app JAR file path in S3
}


resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name        = "my-beanstalk-env"
  application = aws_elastic_beanstalk_application.my_app.name
  #solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Docker 19.03.13-ce"
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Java 8"


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
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
    name      = "SERVER_PORT" # Optional: Specify the server port if needed
    value     = "8080"        # Example port number
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

resource "aws_db_instance" "db_instance" {
  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t2.micro"
  username          = "admin"
  password          = "admin123"

  // Attach the RDS instance to the RDS security group
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

}

resource "aws_autoscaling_group" "beanstalk_asg" {
  launch_configuration = aws_elastic_beanstalk_environment.beanstalk_env.name

  min_size         = 1
  max_size         = 3 # 1 default instance + 2 spot instances
  desired_capacity = 1

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

##
##

output "beanstalk_elb_endpoint" {
  value = aws_elastic_beanstalk_environment.beanstalk_env.endpoint_url
}

output "beanstalk_arn" {
  value = aws_elastic_beanstalk_environment.beanstalk_env.arn
}

output "rds_endpoint" {
  value = aws_db_instance.db_instance.endpoint
}

output "rds_username" {
  value = aws_db_instance.db_instance.username
}

output "rds_password" {
  value = aws_db_instance.db_instance.password
  sensitive = true
}
