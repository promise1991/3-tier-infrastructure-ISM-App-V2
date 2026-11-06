
# =======================================================================================
# create the route tables
# =======================================================================================

# ---------------------------------------------------------------------------------
# create the public route table
# ---------------------------------------------------------------------------------
resource "aws_route_table" "rtb_public1a" {
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "Three-Tier-VPC-Public-Route-Table"
  }
}

resource "aws_route_table" "rtb_public1b" {
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "Three-Tier-VPC-Public-Route-Table"
  }
}
# ---------------------------------------------------------------------------------
# create the private route table for app subnet 1a and 1b
# ---------------------------------------------------------------------------------
resource "aws_route_table" "rtb_app_private_1a" {
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "Three-Tier-VPC-Private-App-Route-Table"
  }
}

resource "aws_route_table" "rtb_app_private_1b" {
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "Three-Tier-VPC-Private-App-Route-Table-2"
  }
}
# ---------------------------------------------------------------------------------
# create the private route table for data subnet 1a and 1b
# ---------------------------------------------------------------------------------
resource "aws_route_table" "rtb_data_private" {
  vpc_id = aws_vpc.three_tier.id

  tags = {
    Name = "Three-Tier-VPC-Private-Data-Route-Table"
  }
}


# =======================================================================================
# Internet configuration for public subnets
# =======================================================================================

# ----------------------------------------------------------------------------
# we are creating a rule for the public subnet route table
# ------------------------------------------------------------------------------
# “We are adding a rule to the public subnet’s map that says:
# For any traffic going anywhere on the internet, send it out through the Internet Gateway.
# Without this rule, servers in the public subnet cannot reach the internet.”

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.rtb_public1a.id
  destination_cidr_block = "0.0.0.0/0"                 # This entry sends all other subnet traffic to the internet gateway, which enables the instances in the subnet to access the internet.
  gateway_id             = aws_internet_gateway.igw.id // Link to the Internet Gateway
}

resource "aws_route" "public_internet-b" {
  route_table_id         = aws_route_table.rtb_public1b.id
  destination_cidr_block = "0.0.0.0/0"                 # This entry sends all other subnet traffic to the internet gateway, which enables the instances in the subnet to access the internet.
  gateway_id             = aws_internet_gateway.igw.id // Link to the Internet Gateway
}



# ---------------------------------------------------------------------------------
#  Internet configuration for private subnets that will use NAT Gateway for internet access
# ---------------------------------------------------------------------------------
resource "aws_route" "private_app_nat_route" {
  route_table_id         = aws_route_table.rtb_app_private_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat1a.id
}

resource "aws_route" "app_private_2_nat" {
  route_table_id         = aws_route_table.rtb_app_private_1b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat1b.id
}

# =======================================================================================
# We have given the Route Tables internet access but we  want to associate the public route tables(rtb_public)
# with public subnets(web_public_subnet1a, web_public_subnet1b)
# ------------------------------------------------------------------------------------------------------------------

# PUBLIC SUBNET ASSOCIATIONS
# resource "aws_route_table_association" "public_1a" {
#   subnet_id      = aws_subnet.web_public_subnet1a.id
#   route_table_id = aws_route_table.rtb_public.id
# }

# resource "aws_route_table_association" "public_1b" {
#   subnet_id      = aws_subnet.web_public_subnet1b.id
#   route_table_id = aws_route_table.rtb_public.id
# }

# # PUBLIC(JUMPBOX) SUBNET ASSOCIATIONS   
# resource "aws_route_table_association" "jumphost_public_1a" {
#   subnet_id      = aws_subnet.jumphost_public_jh_subnet1a.id
#   route_table_id = aws_route_table.rtb_public.id
# }

# # PUBLIC(JUMPBOX) SUBNET ASSOCIATIONS   
# resource "aws_route_table_association" "jumphost_public_1b" {
#   subnet_id      = aws_subnet.jumphost_public_jh_subnet1b.id
#   route_table_id = aws_route_table.rtb_public.id
# }

locals { // Define a local map for public subnet IDs
  public_subnets = {
    web_1a = aws_subnet.web_public_subnet1a.id // First public subnet ID
    web_1b = aws_subnet.web_public_subnet1b.id // Second public subnet ID
  }
}
# Loop to create associations for public subnets
resource "aws_route_table_association" "public_subnet_associations" { // Resource to associate public subnets with the public route table
  for_each       = local.public_subnets                               // Iterate over each public subnet
  subnet_id      = each.value                                         // Assign the current subnet ID from the map
  route_table_id = aws_route_table.rtb_public1a.id                    // Associate with the public route table
}

# -------------------------------------------------------------------------------------------------------------------------------------------------------------
# Associate private route tables(app_private_subnet1a and app_private_subnet1b) with private subnets(app_private_subnet1a, app_private_subnet1b) respectively
# -------------------------------------------------------------------------------------------------------------------------------------------------------------


# PRIVATE SUBNET ASSOCIATIONS
resource "aws_route_table_association" "pvt_app_1a" {
  subnet_id      = aws_subnet.app_private_subnet1a.id
  route_table_id = aws_route_table.rtb_app_private_1a.id
}

resource "aws_route_table_association" "pvt_app_1b" {
  subnet_id      = aws_subnet.app_private_subnet1b.id
  route_table_id = aws_route_table.rtb_app_private_1b.id
}


# ------------------------------------------------------------------------------------------------------------------
# Associate private route tables(rtb_data_private) with private subnets(data_private_subnet1a, data_private_subnet1b)
# ------------------------------------------------------------------------------------------------------------------

resource "aws_route_table_association" "pvt_data_1a" {
  subnet_id      = aws_subnet.data_private_subnet["a"].id
  route_table_id = aws_route_table.rtb_data_private.id
}

resource "aws_route_table_association" "pvt_data_1b" {
  subnet_id      = aws_subnet.data_private_subnet["b"].id
  route_table_id = aws_route_table.rtb_data_private.id
}

# What it does:
# - Creates route tables for public(rtb_public) and private subnets(rtb_app_private_1a, rtb_app_private_1b, rtb_data_private).
# - Adds routes to the public route table to direct internet-bound traffic to the Internet Gateway.
# - Adds routes to the private route tables to direct outgoing internet-bound traffic to the NAT Gateways.
# - Associates each route table with the appropriate subnets to enforce the routing rules.  


