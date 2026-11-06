
# Two Elastic IP creation for NAT Gateway
resource "aws_eip" "nat_eip1a" {
  domain = "vpc"
  tags   = { Name = "nat-eip1a" }
}

resource "aws_eip" "nat_eip1b" {
  domain = "vpc"
  tags   = { Name = "nat-eip1b" }
}

# What it does:
# - Allocates a static public IP in AWS.
# - domain = "vpc" means the EIP is intended for use in a VPC (not EC2-Classic).
# - This EIP will later be attached to the NAT Gateway.



# ------------------------------------------------------
# NAT Gateway creation (aws_nat_gateway)
resource "aws_nat_gateway" "nat1a" {
  allocation_id = aws_eip.nat_eip1a.id              // Link the EIP to the NAT Gateway
  subnet_id     = aws_subnet.web_public_subnet1a.id // Place the NAT Gateway in the public subnet

  tags = { Name = "NAT1a" }
}

resource "aws_nat_gateway" "nat1b" {
  allocation_id = aws_eip.nat_eip1b.id              // Link the EIP to the NAT Gateway
  subnet_id     = aws_subnet.web_public_subnet1b.id // Place the NAT Gateway in the public subnet

  tags = { Name = "NAT1b" }
}
# What it does:
# - Creates a managed NAT Gateway inside a public subnet (public_1a & public_1b).
# - allocation_id links the NAT Gateway to the EIP you just created.
# - The NAT Gateway provides outbound internet access for private subnets while keeping the private instances inaccessible from the internet.


# Why NAT must be in a public subnet
# A NAT Gateway needs:
# - A public IP address (EIP)
# - A route to the internet through the Internet Gateway. This is only possible in a public subnet.