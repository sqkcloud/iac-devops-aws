resource "aws_lb" "this" {
  count              = var.create_alb ? 1 : 0
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "this" {
  count    = var.create_alb ? 1 : 0
  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "private_app" {
  count            = var.create_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = var.private_app_instance_id
  port             = 80
}

resource "aws_lb_listener" "http" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}
