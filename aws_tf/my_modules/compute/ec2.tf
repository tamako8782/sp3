////////////////////// data //////////////////////

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"

}


////////////////////// locals //////////////////////

locals {
  web_subnet_ids = [for name,id in var.subnet_ids : id if contains(["web-subnet-01", "web-subnet-02"], name)]
}


locals {
  api_subnet_ids = [for name,id in var.subnet_ids : id if contains(["api-subnet-01", "api-subnet-02"], name)]
}

# ローカルに保存するファイル名を定義
locals {
  public_key_file  = "./.key_pair/${var.key_name}.id_rsa.pub"
  private_key_file = "./.key_pair/${var.key_name}.id_rsa"
}




////////////////////// resource //////////////////////


resource "aws_launch_template" "web_launch_template" {
  name = "web-launch-template"
  image_id = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = aws_key_pair.key_pair.key_name
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git nginx
    systemctl enable nginx
    systemctl start nginx
    git clone https://github.com/tamako8782/sp2.git
    rm -rf /usr/share/nginx/html/*
    mv sp2/web/src/* /usr/share/nginx/html/
    cd /usr/share/nginx/html/
    sed -i 's|const apiIp = "APIIPADDRESS"|const apiIp = "${aws_lb.api_nlb.dns_name}"|' /usr/share/nginx/html/index.js
    systemctl restart nginx
    EOF
  )
}


resource "aws_autoscaling_group" "web_autoscaling_group" {
  name = "web-autoscaling-group"
  launch_template {
    id = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 4
  
  target_group_arns = [aws_lb_target_group.web_alb_target_group.arn]

  vpc_zone_identifier = local.web_subnet_ids

  tag {
      key = "Name"
      value = "web-server"
      propagate_at_launch = true
    }

}


resource "aws_launch_template" "api_launch_template" {
  name = "api-launch-template"
  image_id = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name = aws_key_pair.key_pair.key_name
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git
    yum install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
    yum install -y mysql
    systemctl start mysqld
    systemctl enable mysqld
    git clone https://github.com/tamako8782/sp2.git
    cat <<EOT >> /sp2/api/.env
    DB_USER=${var.db_username}
    DB_PASS=${var.db_password}
    DB_HOST=${var.db_address}
    DB_PORT=${var.db_port}
    DB_NAME=${var.db_name}
    EOT
    
     ./sp2/api/api_for_linux_amd2 
  EOF
  )
}

resource "aws_autoscaling_group" "api_autoscaling_group" {
  name = "api-autoscaling-group"
  launch_template {
    id = aws_launch_template.api_launch_template.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 4
  target_group_arns = [aws_lb_target_group.api_nlb_target_group.arn]

  vpc_zone_identifier = local.api_subnet_ids

  tag {
      key = "Name"
      value = "api-server"
      propagate_at_launch = true
    }
}



# 秘密鍵を生成
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 秘密鍵をローカルに保存

resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

# 公開鍵をローカルに保存
resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh
  provisioner "local-exec" {
    command = "chmod 600 ${local.public_key_file}"
  }
}

# 公開鍵をAWSに保存
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh
}

////////////////////// output //////////////////////

output "api_security_group_id" {
  value = aws_security_group.api.id
}
