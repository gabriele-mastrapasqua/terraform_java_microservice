variable "aws_region" {
  description = "AWS Region to use."
  type        = string
  default     = "us-east-1"
}

variable "beanstalk_app_name" {
  description = "Beanstalk app name to use"
  type        = string
  default     = "JavaMicroTerraformTestApp"
}

variable "beanstalk_env_name" {
  description = "Beanstalk environment name to use"
  type        = string
  default     = "JavaMicroTerraformTestEnv"
}

variable "beanstalk_app_version" {
  description = "Beanstalk app version name to use"
  type        = string
  default     = "v1"
}

variable "beanstalk_app_port" {
  description = "Beanstalk app server port to use"
  type        = string
  default     = "8080"
}


variable "ec2_instance_type" {
  description = "EC2 instance type to use."
  type        = string
  default     = "t2.micro"
}

variable "ec2_scaling_desired" {
  description = "EC2 instances desired."
  type        = number
  default     = 1
}

variable "ec2_scaling_max" {
  description = "EC2 max number of instances desired."
  type        = number
  default     = 3
}


variable "rds_instance_type" {
  description = "RDS instance type to use."
  type        = string
  default     = "db.t2.micro"
}

# NOTE: override those with tfvars in production! this is only for testing purpose.
variable "rds_username" {
  description = "RDS db username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_password" {
  description = "RDS db password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "java_application_artifact_name" {
  description = "Java Jar name to use"
  type        = string
  default     = "rest-service-0.0.1-SNAPSHOT.jar"
}
