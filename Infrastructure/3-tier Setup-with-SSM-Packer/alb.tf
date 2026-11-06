resource "aws_lb" "web_alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  internal           = false // This ALB is PUBLIC, so users can access it from the internet

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [ //internet-facing ALBs MUST live in public subnets.
    aws_subnet.web_public_subnet1a.id,
    aws_subnet.web_public_subnet1b.id
  ]
}

# LISTENER ---------------------------------------------------------

resource "aws_lb_listener" "http" { // means ALB should listen for incoming HTTP traffic on port 80 and forward it to the target group
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}


# TARGET GROUP ---------------------------------------------------------

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier.id

  health_check { // ALB continiuosly check servers health just to make sure they can serve in good condition
    path = "/"
  }
}

# COMMENTING ATACH TARGET GROUP TO WEB EC2 INSTANCES SO Auto Scaling Groups will automatically attach instances.
# Without autoscaling you manually attach EC2, With autoscaling new instances come/go automatically So ASG handles registration.

# resource "aws_lb_target_group_attachment" "web1" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id        = aws_instance.web-Server1.id
#   port             = 80
# }

# resource "aws_lb_target_group_attachment" "web2" {
#   target_group_arn = aws_lb_target_group.web_tg.arn
#   target_id        = aws_instance.web-Server2.id
#   port             = 80
# }

# --------------------------------------------------------------------------------------------------------------------
# INTERNAL ALB FOR APP TIER
# --------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = true # ← internal, not internet-facing, only internal VPC traffic allowed.

  security_groups = [aws_security_group.app_alb_sg.id]

  subnets = [
    aws_subnet.app_private_subnet1a.id,
    aws_subnet.app_private_subnet1b.id
  ]
}

# ------------------------------------------------------------
# APP ALB TARGET GROUP
# ------------------------------------------------------------

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier.id

  health_check {
    path                = "/api/products"
    port                = "5000"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200,201" # ← add this line
  }
}

# ------------------------------------------------------------
# COMMENTING ATTACH APP SERVERS TO TARGET GROUP SO SINCE AUTOSCALING AUTOMATICALLY ATTACH THEM
# ------------------------------------------------------------

# resource "aws_lb_target_group_attachment" "app1" {
#   target_group_arn = aws_lb_target_group.app_tg.arn
#   target_id        = aws_instance.app-Server1.id
#   port             = 5000
# }

# resource "aws_lb_target_group_attachment" "app2" {
#   target_group_arn = aws_lb_target_group.app_tg.arn
#   target_id        = aws_instance.app-Server2.id
#   port             = 5000
# }

# ------------------------------------------------------------
# APP ALB LISTENER
# ------------------------------------------------------------

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 5000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ------------------------------------------------------------
# APP ALB SECURITY GROUP
# ------------------------------------------------------------

resource "aws_security_group" "app_alb_sg" {
  name   = "app-alb-sg"
  vpc_id = aws_vpc.three_tier.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id] # only from web tier
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-alb-sg"
  }
}

# ------------------------------------------------------------
# ALLOW APP ALB TO REACH APP SERVERS
# ------------------------------------------------------------

resource "aws_security_group_rule" "app_from_alb_ingress" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app-sg.id
  source_security_group_id = aws_security_group.app_alb_sg.id
}