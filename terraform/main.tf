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

# we also need a iam role for beanstalk to create ec2  
resource "aws_iam_role" "elasticbeanstalk_service_role" {
  name               = "aws-elasticbeanstalk-service-role"
  description = "Allows Elastic Beanstalk to create and manage AWS resources on your behalf."
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk",
  "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth",
  "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
  ]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "elasticbeanstalk_ec2_role" {
  name               = "aws-elasticbeanstalk-ec2-role"
  description = "Role to link beanstalk and ec2"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
    ]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach policies to the IAM role as needed
resource "aws_iam_role_policy_attachment" "elasticbeanstalk_ec2_role_attachment" {
  role       = aws_iam_role.elasticbeanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


resource "aws_iam_instance_profile" "elasticbeanstalk_ec2_instance_profile" {
  name = "aws-elasticbeanstalk-ec2-instance-profile"
  role = aws_iam_role.elasticbeanstalk_ec2_role.name
}


###
###
###


# bucket to deploy the application artifacts
resource "aws_s3_bucket" "default" {
  bucket = var.s3_deploy_artifact_bucket_name
}

resource "aws_s3_object" "default" {
  bucket = aws_s3_bucket.default.id
  key    = "beanstalk/${var.java_application_artifact_name}"
  source = "../code/build/libs/${var.java_application_artifact_name}"
}



resource "aws_elastic_beanstalk_application" "my_app" {
  name = var.beanstalk_app_name
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = var.beanstalk_app_version
  application = aws_elastic_beanstalk_application.my_app.name
  description = "My Java micro application version 1"
  bucket      = aws_s3_bucket.default.id
  key         = aws_s3_object.default.id
}


resource "aws_elastic_beanstalk_environment" "beanstalk_env" {
  name        = var.beanstalk_env_name
  application = aws_elastic_beanstalk_application.my_app.name
  #solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Docker 19.03.13-ce"
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Corretto 17"


  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # needed to enable beanstalk to create ec2
  setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name = "IamInstanceProfile"
      value = aws_iam_instance_profile.elasticbeanstalk_ec2_instance_profile.id # was .name
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.elasticbeanstalk_service_role.name
  }

  // Attach the security group to the Elastic Beanstalk environment
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_sg.name # check, this should be .id!
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.ec2_instance_type
  }
  
  setting {
        namespace = "aws:autoscaling:asg"
        name      = "MaxSize"
        value     = var.ec2_scaling_max
    }

    setting {
        namespace = "aws:autoscaling:asg"
        name      = "MinSize"
        value     = var.ec2_scaling_desired
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
