resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for RDS instances"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow MySQL traffic from within VPC"
  }

  tags = local.tags
}

module "facilities_db" {
  source = "./modules/relational-database-service"

  identifier             = "${local.name}-facilities"
  engine                 = "mysql"
  engine_version         = "8.0"
  major_engine_version   = "8.0"
  family                 = "mysql8.0"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_name                = "facilities"
  username               = "dbadmin"

  vpc_security_group_ids = [aws_security_group.rds.id]
  
  create_db_subnet_group = true
  subnet_ids             = module.vpc.public_subnets
  
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = local.tags
}
