//有償になるので一旦使わん
//resource "aws_eip" "api_eip1a" {
//  domain = "vpc"
//  tags = {
//    Name = "api-eip1a"
//  }
//}
//
//resource "aws_eip" "api_eip1c" {
//  domain = "vpc"
//  tags = {
//    Name = "api-eip1c"
//  }
//}
//
locals {
  alb_subnet_ids = [for name,id in var.subnet_ids : id if contains(["alb-subnet-01", "alb-subnet-02"], name)]
}

resource "aws_lb" "api_nlb" {
  name = "api-nlb"
  internal = false
  load_balancer_type = "network"
  subnets = local.alb_subnet_ids
  enable_deletion_protection = false

//有償になるので一旦使わん
//  subnet_mapping {
//    subnet_id = local.api_subnet_ids[0]
//    allocation_id = aws_eip.api_eip.id
//  }
//
//  subnet_mapping {
//    subnet_id = local.api_subnet_ids[1]
//    allocation_id = aws_eip.api_eip1c.id
//  }
//

  tags = {
    Name = "api-nlb"
  }
}



resource "aws_lb_target_group" "api_nlb_target_group" {
  name_prefix = "apinlb"
  port = 8080
  protocol = "TCP"
  vpc_id = var.vpc_id
  deregistration_delay = 300
  health_check {
    port = 8080
    protocol = "TCP"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }

  lifecycle {
    create_before_destroy = true
  }
  
}



resource "aws_lb_listener" "api_nlb_listener" {
  load_balancer_arn = aws_lb.api_nlb.arn
  port = "8080"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.api_nlb_target_group.arn
  }
}

////////////////////// output //////////////////////

output "api_nlb_arn" {
  value = aws_lb.api_nlb.arn
}

output "api_nlb_endpoint" {
  value = aws_lb.api_nlb.dns_name
}
