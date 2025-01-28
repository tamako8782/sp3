variable "vpc_cidr_block" {
  type    = string
}

variable "subnet_params" {
  type    = list(object({
    cidr_block = string
    availability_zone = string
    map_public_ip_on_launch = bool
    tags = object({
      Name = string
    })
  }))
}

# VPCの作成
resource "aws_vpc" "sprint_vpc" {
  cidr_block           = var.vpc_cidr_block # ネットワークの範囲を指定
  enable_dns_support   = true          # DNSサポートを有効化
  enable_dns_hostnames = true          # ホスト名解決を有効化
  tags = {
    Name = "reservation-vpc" # リソースの識別用タグ
  }
}

# インターネットゲートウェイの作成

resource "aws_internet_gateway" "sprint_igw" {
  vpc_id = aws_vpc.sprint_vpc.id
  tags = {
    Name = "reservation-ig"
  }
}

# すべてのサブネットはここで作る
resource "aws_subnet" "sprint_sub" {
  for_each = {for subnet in var.subnet_params : subnet.tags.Name => subnet}

  vpc_id                  = aws_vpc.sprint_vpc.id
  cidr_block              = each.value.cidr_block     
  availability_zone       = each.value.availability_zone 
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  tags = {
    Name = each.value.tags.Name
  }
}


# ルートテーブルの作成(web)

resource "aws_route_table" "sprint_route_table_web" {
  vpc_id = aws_vpc.sprint_vpc.id
  tags = {
    Name = "web-routetable"
  }
}

# ルートテーブルの作成(alb)
resource "aws_route_table" "sprint_route_table_alb" {
  vpc_id = aws_vpc.sprint_vpc.id
  tags = {
    Name = "alb-routetable"
  }
}

# インターネットゲートウェイ向けのルート(web)

resource "aws_route" "sprint_web_route" {
  route_table_id         = aws_route_table.sprint_route_table_web.id
  gateway_id             = aws_internet_gateway.sprint_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# インターネットゲートウェイ向けのルート(alb)

resource "aws_route" "sprint_alb_route" {
  route_table_id         = aws_route_table.sprint_route_table_alb.id
  gateway_id             = aws_internet_gateway.sprint_igw.id
  destination_cidr_block = "0.0.0.0/0"
}



# EIPの作成
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

# natゲートウェイの作成
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.sprint_sub["web-subnet-01"].id

  tags = {
    Name = "nat-gateway"
  }
}

# API用ルートテーブルの作成
resource "aws_route_table" "sprint_route_table_api" {
  vpc_id = aws_vpc.sprint_vpc.id
  tags = {
    Name = "api-routetable"
  }
}


# API用ルート_natゲートウェイ向け
resource "aws_route" "sprint_api_route" {
  route_table_id         = aws_route_table.sprint_route_table_api.id
  gateway_id             = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}


# ルートテーブルとサブネットの関連付け(web)
resource "aws_route_table_association" "sprint_route_asso_igw_web" {
  for_each = {
    for key, subnet in aws_subnet.sprint_sub :
    key => subnet if contains(["web-subnet-01", "web-subnet-02"], subnet.tags["Name"])
  }

  route_table_id = aws_route_table.sprint_route_table_web.id
  subnet_id      = each.value.id
}

# ルートテーブルとサブネットの関連付け(alb)
resource "aws_route_table_association" "sprint_route_asso_igw_alb" {
  for_each = {
    for key, subnet in aws_subnet.sprint_sub :
    key => subnet if contains(["alb-subnet-01", "alb-subnet-02"], subnet.tags["Name"])
  }

  route_table_id = aws_route_table.sprint_route_table_alb.id
  subnet_id      = each.value.id
}

# ルートテーブルとサブネットの関連付け(api)
resource "aws_route_table_association" "sprint_route_asso_nat_api" {
  for_each = {
    for key, subnet in aws_subnet.sprint_sub :
    key => subnet if contains(["api-subnet-01", "api-subnet-02"], subnet.tags["Name"])
  }

  route_table_id = aws_route_table.sprint_route_table_api.id
  subnet_id      = each.value.id
}


output "vpc_id" {
  value = aws_vpc.sprint_vpc.id
}


output "subnet_ids" {
  value = {for key, subnet in aws_subnet.sprint_sub : subnet.tags.Name => subnet.id}
}

output "route_table_web_id" {
  value = aws_route_table.sprint_route_table_web.id
}

output "route_table_alb_id" {
  value = aws_route_table.sprint_route_table_alb.id
}

output "route_table_api_id" {
  value = aws_route_table.sprint_route_table_api.id
}
