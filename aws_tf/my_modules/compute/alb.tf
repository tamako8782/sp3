////////////////////// resource //////////////////////

resource "aws_lb" "web_alb" {
  name = "web-alb"
  
  internal = false
  load_balancer_type = "application"
  ip_address_type = "ipv4"
  subnets = local.web_subnet_ids
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "web-alb"
  }
}

resource "aws_lb_target_group" "web_alb_target_group" {
  name_prefix = "webalb"
  port = 80
  protocol_version = "HTTP1"
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "instance"
  health_check {
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = "200-299,301"
  }

    lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "web_alb_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web_alb_target_group.arn
  }
}



////////////////////// output //////////////////////

output "web_alb_arn" {
  value = aws_lb.web_alb.arn
}

output "web_alb_endpoint" {
  value = aws_lb.web_alb.dns_name
}
