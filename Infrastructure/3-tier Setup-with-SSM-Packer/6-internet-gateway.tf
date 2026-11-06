resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.three_tier.id // Associate the IGW with the VPC created earlier

  tags = {
    Name = "Three-Tier-VPC-IGW"
  }
}
