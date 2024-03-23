
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"

  // Allow inbound traffic from Elastic Beanstalk security group
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    #security_groups = [aws_security_group.beanstalk_sg.id]
  }

  // Allow outbound traffic to Elastic Beanstalk security group on port 80
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    #security_groups = [aws_security_group.beanstalk_sg.id]
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.rds_instance_type
  username          = var.rds_username
  password          = var.rds_password

  // Attach the RDS instance to the RDS security group
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

}
