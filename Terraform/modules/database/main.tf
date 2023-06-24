locals {
  user_name = "zlaval"
  db_name   = "pppdb"
}

# Create an AWS database subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${var.namespace}-${var.project_name}-group"
  subnet_ids = [
    var.subnet.private_a.id,
    var.subnet.private_b.id
  ]
}

# Create an AWS security group for the database
resource "aws_security_group" "database" {
  name        = "${var.namespace}-${var.project_name}-db"
  description = "Allow traffic to database"
  vpc_id      = var.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [var.app_security_group.id]
    self            = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

# Generate a random password for the database
resource "random_password" "password" {
  length  = 16
  special = false
}

# Create an AWS RDS database instance
resource "aws_db_instance" "database" {
  instance_class         = "db.t3.micro"
  allocated_storage           = 10
  allow_major_version_upgrade = true
  engine                 = "postgres"
  #engine_version         = "14.1"
  db_name                     = local.db_name
  username                    = local.user_name
  password                    = random_password.password.result
  skip_final_snapshot         = true
  multi_az                    = false
  backup_retention_period     = 0
  identifier                  = "${var.namespace}-${var.project_name}-db"
  db_subnet_group_name        = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  #lifecycle {
  # prevent_destroy = true
  #}
}

# **** Implementing DocumentDB as mongoDB

locals {
  user_name_2 = "dbuser"
}

resource "aws_docdb_subnet_group" "docdb_subnet" {
  name       = "${var.namespace}-${var.project_name}-docdb-group"
  subnet_ids = [
    var.subnet.private_a.id,
    var.subnet.private_b.id
  ]
}

resource "aws_security_group" "database_docdb" {
  name        = "${var.namespace}-${var.project_name}-docdb"
  description = "Allow traffic to database 2"
  vpc_id      = var.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 27017
    to_port         = 27017
    security_groups = [var.app_security_group.id]
    self            = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "random_password" "password_2" {
  length  = 16
  special = false
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.namespace}-${var.project_name}-docdb-cluster"
  engine                  = "docdb"
  port                    = 27017
  master_username         = local.user_name_2
  # master_password         = random_password.password_2.result
  master_password         = "Spippola21!"
  backup_retention_period = "7"
  preferred_backup_window = "01:00-03:00"
  storage_encrypted       = true
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.docdb_subnet.name
  vpc_security_group_ids  = [
    aws_security_group.database_docdb.id,
  ]
}

resource "aws_docdb_cluster_instance" "default" {
  count              = "1"
  identifier         = "${var.namespace}-${var.project_name}-docdb-cluster-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"
}
