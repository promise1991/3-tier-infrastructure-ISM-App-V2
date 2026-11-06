# ----------------------------------------------------------------
# GITHUB OIDC - Allows GitHub Actions to securely access AWS
# without storing permanent credentials
# ----------------------------------------------------------------

# Step 1: Tell AWS to trust GitHub as an identity provider
# Think of this as registering GitHub in AWS's "trusted list"
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # This is GitHub's unique client ID for AWS
  client_id_list = ["sts.amazonaws.com"]

  # This is GitHub's certificate thumbprint
  # AWS uses this to verify requests actually come from GitHub
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Step 2: Least privilege — Create an IAM Role that GitHub Actions will assume
# This role defines WHAT GitHub is allowed to do in your AWS account
resource "aws_iam_role" "github_actions" {
  name = "${var.app_name}-github-actions-role"

  # Trust Policy — WHO can assume this role
  # Only YOUR specific repos can use this role, nobody else
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # Only these repos can assume this role, this called least privilege — only allow what you need
            "token.actions.githubusercontent.com:sub" = [
              "repo:promise1991/Apps-For-Testing-in-AWS-infrastructure:*",
              "repo:promise1991/3-tier-infrastructure-ISM-App:*"
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-github-actions-role"
  }
}

# Step 3: Define WHAT the GitHub Actions role can do in AWS
# These are the permissions the pipeline needs to:
# - Build AMIs with Packer
# - Update launch templates
# - Trigger ASG instance refresh
resource "aws_iam_policy" "github_actions" {
  name        = "${var.app_name}-github-actions-policy"
  description = "Permissions for GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Packer needs these to build AMIs
        Sid    = "PackerPermissions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateImage",
          "ec2:RegisterImage",
          "ec2:DeregisterImage",
          "ec2:CopyImage",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:RunInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:GetPasswordData",
          "ec2:ModifyImageAttribute",
          "ec2:DescribeInstanceStatus",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DescribeIamInstanceProfileAssociations"
        ]
        Resource = "*"
      },
      {
        # Terraform needs these to update launch templates
        Sid    = "LaunchTemplatePermissions"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        # ASG instance refresh — replaces old instances with new ones
        Sid    = "ASGPermissions"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = "*"
      },
      # {
      #   # SSM — needed by Packer to connect to instances
      #   Sid    = "SSMPermissions"
      #   Effect = "Allow"
      #   Action = [
      #     "ssm:GetParameter",
      #     "ssm:GetParameters",
      #     "ssm:PutParameter"
      #   ]
      #   Resource = "*"
      # },
      # {
      #   # IAM — needed to pass roles to EC2 instances during Packer build
      #   Sid    = "IAMPassRole"
      #   Effect = "Allow"
      #   Action = [
      #     "iam:PassRole",
      #     "iam:GetInstanceProfile"
      #   ]
      #   Resource = "*"
      # },
      # {
      #   # S3 — Terraform needs this if using S3 backend for state
      #   Sid    = "S3Permissions"
      #   Effect = "Allow"
      #   Action = [
      #     "s3:GetObject",
      #     "s3:PutObject",
      #     "s3:ListBucket"
      #   ]
      #   Resource = "*"
      # },

      #       {
      #   "Sid": "PackerSSMCommunicator",
      #   "Effect": "Allow",
      #   "Action": [
      #     "ssm:StartSession",
      #     "ssm:TerminateSession",
      #     "ssm:DescribeSessions",
      #     "ssm:DescribeInstanceInformation",
      #     "ssm:SendCommand",
      #     "ssm:GetCommandInvocation",
      #     "ec2messages:AcknowledgeMessage",
      #     "ec2messages:DeleteMessage",
      #     "ec2messages:FailMessage",
      #     "ec2messages:GetEndpoint",
      #     "ec2messages:GetMessages",
      #     "ec2messages:SendReply",
      #     "ssmmessages:CreateControlChannel",
      #     "ssmmessages:CreateDataChannel",
      #     "ssmmessages:OpenControlChannel",
      #     "ssmmessages:OpenDataChannel"
      #   ],
      #   "Resource": "*"
      # }
    ]
  })
}



# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# Output the role ARN — we'll need this in GitHub Actions pipeline
output "github_actions_role_arn" {
  description = "Role ARN to use in GitHub Actions pipeline"
  value       = aws_iam_role.github_actions.arn
}
