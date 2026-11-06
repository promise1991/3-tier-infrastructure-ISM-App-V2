resource "aws_vpc_endpoint" "ssm" {                 // Creates a VPC endpoint specifically for SSM service.
  vpc_id            = aws_vpc.three_tier.id         // Attaches this endpoint to your VPC.
  service_name      = "com.amazonaws.us-east-1.ssm" // This tells AWS “I want access to the SSM service in us-east-1”
  vpc_endpoint_type = "Interface"                   //This is important: Interface endpoint = private IP inside your subnet
  // Uses ENIs (Elastic Network Interfaces) Works with security groups

  subnet_ids = values(aws_subnet.data_private_subnet)[*].id // This means: Place the endpoint inside your private subnets
  //So your EC2 instances in those subnets can reach it directly.
  security_group_ids = [aws_security_group.ssm_vpce.id] // Controls traffic to the endpoint.Typical rule: Allow HTTPS (port 443) from your EC2 instances

  private_dns_enabled = true
}

// EC2 Messages Endpoint

resource "aws_vpc_endpoint" "ec2messages" { // This endpoint is used for: Communication between EC2 and SSM backend, ssm connection breaks without this
  vpc_id            = aws_vpc.three_tier.id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = values(aws_subnet.data_private_subnet)[*].id
  security_group_ids = [aws_security_group.ssm_vpce.id]

  private_dns_enabled = true
}

// SSM Messages Endpoint

resource "aws_vpc_endpoint" "ssmmessages" { //This handles: Session Manager (interactive shell access)
  // So when you run >>> aws ssm start-session, This endpoint enables:
  //Real-time communication and Shell access (like SSH, but no SSH port)

  vpc_id            = aws_vpc.three_tier.id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = values(aws_subnet.data_private_subnet)[*].id
  security_group_ids = [aws_security_group.ssm_vpce.id]

  private_dns_enabled = true
}



# Secrets Manager Interface Endpoint
# your application servers are in private subnets. This endpoint gives them a private route to AWS Secrets Manager without 
# requiring public internet access or a NAT gateway for that connection.
# The flow we're building is:
# App EC2 → Secrets Manager VPC Endpoint → AWS Secrets Manager

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.three_tier.id
  service_name      = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = values(aws_subnet.data_private_subnet)[*].id
  security_group_ids = [aws_security_group.secretsmanager_vpce.id]

  private_dns_enabled = true
}

# //-----------------------------------------------
# if you want to specify subnets individually instead of using all private data subnets
# //-----------------------------------------------
# subnet_ids = [
#   aws_subnet.private_data_subnet["us-east-1a"].id,
#   aws_subnet.private_data_subnet["us-east-1b"].id
# ]