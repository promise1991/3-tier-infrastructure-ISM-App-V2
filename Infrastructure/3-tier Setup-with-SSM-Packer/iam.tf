// --------------------------------create an IAM role for EC2 instances to use SSM
resource "aws_iam_role" "ssm_ec2_role" {
  name = "${var.app_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({ // trust policy for the role
    Version = "2012-10-17"          // IAM policy version
    Statement = [{
      Effect    = "Allow"                           // Allows EC2 service to assume this role, it can ECS OR EKS
      Principal = { Service = "ec2.amazonaws.com" } // EC2 service principal
      Action    = "sts:AssumeRole"                  // Action to assume the role
    }]
  })
}

// Note that, only one ROLE can be assigned to a resources(ec2 instance) that needs access




//------------------------ATTACH POLICIES TO ROLES------------------------//

// attach the AmazonSSMManagedInstanceCore policy to the role and make sure is static
# resource "aws_iam_role_policy_attachment" "ssm_core" {
#   role       = aws_iam_role.ssm_ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

// attach the AmazonSSMManagedInstanceCore policy to the role and make sure is dynamic based on condition true/false
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  count = var.attach_ssm ? 1 : 0

  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// attach the CloudWatchAgentServerPolicy policy to the role and make sure is dynamic based on variable
resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  count = var.attach_cloudwatch ? 1 : 0

  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}





//---------------------------------- create an instance profile for the EC2 instances to use the IAM role
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.app_name}-ssm-profile"
  role = aws_iam_role.ssm_ec2_role.name
}



# Dedicated IAM role for application EC2 instances

resource "aws_iam_role" "app_ec2_role" {
  name = "${var.app_name}-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Instance profile for application EC2 instances

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.app_name}-app-profile"
  role = aws_iam_role.app_ec2_role.name
}

# Preserve Systems Manager access for application EC2

resource "aws_iam_role_policy_attachment" "app_ssm_attach" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# Application configuration secret in AWS Secrets Manager

resource "aws_secretsmanager_secret" "app_config" {
  name        = "${var.app_name}/production/app-config"
  description = "Production configuration for the application tier"
}

# Allow application EC2 instances to read only their application secret

resource "aws_iam_policy" "app_secrets_policy" {
  name        = "${var.app_name}-app-secrets-policy"
  description = "Allow application EC2 instances to retrieve their application configuration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.app_config.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_secrets_attach" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}