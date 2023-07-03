resource "aws_docdb_subnet_group" "main" {
  name       = "${var.name}-${var.env}"
  subnet_ids = var.subnets
  tags       = merge(var.tags, { Name = "${var.name}-${var.env}" })
}

resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "DOCDB"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allow_db_cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-${var.env}-sg" })
}

resource "aws_docdb_cluster" "main" {
  engine                 = var.engine
  engine_version         = var.engine_version
  cluster_identifier     = "${var.name}-${var.env}"
  master_username        = data.aws_ssm_parameter.db_user.value
  master_password        = data.aws_ssm_parameter.db_pass.value
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = var.kms_arn
  db_subnet_group_name   = aws_docdb_subnet_group.main.id
  vpc_security_group_ids = [aws_docdb_subnet_group.main.id]
  port                   = var.port
  tags                   = merge(var.tags, { Name = "${var.name}-${var.env}" })
}

resource "aws_docdb_cluster_instance" "cluster_instance" {
  count              = var.instance_count
  identifier         = "${var.name}-${var.env}-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family      = "docdb4.0"
  name        = "${var.name}-${var.env}"
  description = "${var.name}-${var.env}"
  tags        = merge(var.tags, { Name = "${var.name}-${var.env}" })
}


