resource "aws_vpc" "three_tier" {
  cidr_block           = "10.5.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Three-Tier-VPC-app"
  }
}
