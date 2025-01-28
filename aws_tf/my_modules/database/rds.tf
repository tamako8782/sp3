variable "db_identifier" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
} 

variable "multi_az" {
  type = bool
}

variable "db_port" {
  type = number
} 

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = map(string)
}

variable "api_security_group_id" {
  type = string
}

locals {
  db_subnet_ids = [for name,id in var.subnet_ids : id if contains(["db-subnet-01", "db-subnet-02"], name)]
  
}

resource "aws_db_subnet_group" "sprint_db_sub_group" {
  name        = "db-subnet-group"
  description = "sprint-db-subnet-group"
  subnet_ids  = local.db_subnet_ids
}


# dbインスタンスの作成
resource "aws_db_instance" "sprint_db_instance" {
  identifier           = var.db_identifier
  instance_class       = "db.t3.micro"
  engine               = "mysql"
  engine_version       = "8.0.40"
  db_subnet_group_name = aws_db_subnet_group.sprint_db_sub_group.name

  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  allocated_storage = 20
  storage_type      = "gp2"
  multi_az          = var.multi_az

  vpc_security_group_ids = [aws_security_group.tamako_rds_sg.id]

  # 削除時にsnapshot取得をスキップする設定
  skip_final_snapshot = true
}

resource "aws_security_group" "tamako_rds_sg" {
  name        = "tamako-rds-sg"
  description = "tamako-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.api_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




output "db_endpoint" {
  value = aws_db_instance.sprint_db_instance.endpoint
}

output "db_address" {
  value = aws_db_instance.sprint_db_instance.address
}

