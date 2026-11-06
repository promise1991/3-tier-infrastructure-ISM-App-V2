
# ---------------- webtier security group

resource "aws_security_group" "web-sg" {
  name = "web-sg"

  vpc_id = aws_vpc.three_tier.id

  #-------------- HTTP/HTTPS from anywhere
  ingress {
    description = "Open port 22 for cli access to the EC2 instance"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # to be accessible from anywhere
  }


  egress {
    description = "rules to allow access of the resources inside the vpc to the internet"
    from_port   = 0             # not restricting the request to any port out there is to set the value to 0
    to_port     = 0             #same here
    protocol    = "-1"          # not to restricct the protocal to a particular ones, we set this to "any" by using -1
    cidr_blocks = ["0.0.0.0/0"] # any ip address out there
  }

  tags = {
    Name = "Web-SG"
  }
}

# ------------------------------------------------------------
# ALB SECURITY GROUPS
# ------------------------------------------------------------

resource "aws_security_group" "alb_sg" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ----------------------------------------------------------------------


resource "aws_security_group" "app-sg" {
  name = "app-sg"

  vpc_id = aws_vpc.three_tier.id

  ingress {
    description     = "Inbound only from Web SG"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id] #allow access from the web security group to the app security group
  }


  egress {
    description = "rules to allow access of the resources inside the vpc to the internet"
    from_port   = 0             # not restricting the request to any port out there is to set the value to 0
    to_port     = 0             #same here
    protocol    = "-1"          # not to restricct the protocal to a particular ones, we set this to "any" by using -1
    cidr_blocks = ["0.0.0.0/0"] # any ip address out there
  }

  tags = {
    Name = "app-tier-security-group"
  }
}



# --------------------------Create data-tier & VPC Endpoint security groups without rules----------------

resource "aws_security_group" "db-tier-sg" {
  name   = "db-tier-sg"
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "db-tier-security-group"
  }
}

resource "aws_security_group" "ssm_vpce" {
  name   = "ssm-vpce-sg"
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "ssm-vpce-sg"
  }
}


resource "aws_security_group" "secretsmanager_vpce" {
  name   = "secretsmanager-vpce-sg"
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "secretsmanager-vpce-sg"
  }
}

# --------------------------Add rules to break the circle for Data-tier SG-VPC Endpoint egress----------------

resource "aws_security_group_rule" "db_tier_to_ssm_vpce_egress" {
  type      = "egress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.db-tier-sg.id
  source_security_group_id = aws_security_group.ssm_vpce.id
}

# --------------------------Add rules to break the circle for VPC Endpoint ingress----------------

resource "aws_security_group_rule" "ssm_vpce_from_db_tier_ingress" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.ssm_vpce.id
  source_security_group_id = aws_security_group.db-tier-sg.id
}


# ----------------------------------------------VPC Endpoint SG rules egress----------------------------------------------

resource "aws_security_group_rule" "ssm_vpce_egress" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"

  security_group_id = aws_security_group.ssm_vpce.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "secretsmanager_from_app_ingress" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.secretsmanager_vpce.id
  source_security_group_id = aws_security_group.app-sg.id
}


# ------This approach is used to break the circular dependency between the security groups----------------------------------------------

# ------------------------------------------------------------
# MONITORING SECURITY GROUP
# This is for the one EC2 that runs Prometheus (collects metrics) and Grafana (shows dashboards).
# Your monitoring server needs to use SSM too, so you can connect to it securely without opening it to the internet.
# You do SSM port-forwarding to see Grafana.
# ------------------------------------------------------------

resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring-sg"
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "monitoring-sg"
  }
}

# Allow SSM access to monitoring instance
# Why: We access Grafana via SSM port forwarding
#      No need to open ports to internet!
resource "aws_security_group_rule" "monitoring_ssm_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.monitoring_sg.id
  source_security_group_id = aws_security_group.ssm_vpce.id
}

resource "aws_security_group_rule" "ssm_vpce_from_monitoring_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ssm_vpce.id
  source_security_group_id = aws_security_group.monitoring_sg.id
}

# Allow monitoring to scrape Node Exporter on web instances
# Why: Prometheus needs to pull metrics from port 9100
#      on every web EC2 instance every 15 seconds
resource "aws_security_group_rule" "monitoring_scrape_web" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.monitoring_sg.id
  source_security_group_id = aws_security_group.web-sg.id
}

# Allow monitoring to scrape Node Exporter on app instances
resource "aws_security_group_rule" "monitoring_scrape_app" {
  type                     = "egress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.monitoring_sg.id
  source_security_group_id = aws_security_group.app-sg.id
}

# Allow general outbound from monitoring
# Why: Needs internet access for package updates
#      and reaching AWS APIs
resource "aws_security_group_rule" "monitoring_general_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.monitoring_sg.id
}

# ------------------------------------------------------------
# ALLOW NODE EXPORTER ON WEB INSTANCES
# From monitoring instance only
# ------------------------------------------------------------

# Why: Web instances need to ACCEPT incoming connections
#      on port 9100 from the monitoring instance
#      Without this, Prometheus can't collect web metrics
resource "aws_security_group_rule" "web_node_exporter_ingress" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web-sg.id
  source_security_group_id = aws_security_group.monitoring_sg.id
}

# ------------------------------------------------------------
# ALLOW NODE EXPORTER ON APP INSTANCES
# From monitoring instance only
# ------------------------------------------------------------

# Why: Same as above but for app tier instances
resource "aws_security_group_rule" "app_node_exporter_ingress" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app-sg.id
  source_security_group_id = aws_security_group.monitoring_sg.id
}
