
# ----------------------------------------------------------------
# PUBLIC SUBNETS
resource "aws_subnet" "web_public_subnet1a" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "10.5.4.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "web_public_subnet1a" }
}

resource "aws_subnet" "web_public_subnet1b" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "10.5.5.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "web__subnet1b" }
}


# ----------------------------------------------------------------
# PRIVATE APP SUBNETS
resource "aws_subnet" "app_private_subnet1a" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "10.5.8.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "app_private_subnet1a" }
}

resource "aws_subnet" "app_private_subnet1b" {
  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = "10.5.9.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "app_private_subnet1b" }
}



# ----------------------------------------------------------------
# PRIVATE DATA SUBNETS

# resource "aws_subnet" "data_private_subnet1a" {
#   vpc_id            = aws_vpc.three_tier.id
#   cidr_block        = "10.5.10.0/24"
#   availability_zone = "us-east-1a"

#   tags = { Name = "data_private_subnet1a" }
# }

# resource "aws_subnet" "data_private_subnet1b" {
#   vpc_id            = aws_vpc.three_tier.id
#   cidr_block        = "10.5.11.0/24"
#   availability_zone = "us-east-1b"

#   tags = { Name = "data_private_subnet1b" }
# }

# ---------approach using for_each to create data private subnets 1a and 1b ----------
resource "aws_subnet" "data_private_subnet" {
  for_each = {
    a = { cidr = "10.5.10.0/24", az = "us-east-1a" }
    b = { cidr = "10.5.11.0/24", az = "us-east-1b" }
  }

  vpc_id            = aws_vpc.three_tier.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "data_private_subnet-${each.key}"
  }

}