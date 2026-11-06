


# ----------------------------------------------------------------
# WEB SERVERS
#----------------------------------------------------------------------
resource "aws_instance" "web-Server1" {
  ami           = "ami-013fe20e135b729e4" # Custom AMI for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  # subnet_id     =  var.subnets[1]
  subnet_id              = aws_subnet.web_public_subnet1a.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data              = templatefile("./web-tier.sh", {})

  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true # to make sure public ip is display
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "web-EC2"
  }
}



resource "aws_instance" "web-Server2" {
  ami           = "ami-013fe20e135b729e4" # Custom AMI for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  # subnet_id     =  var.subnets[1]
  subnet_id              = aws_subnet.web_public_subnet1b.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  user_data              = templatefile("./web-tier.sh", {})
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name



  associate_public_ip_address = true # to make sure public ip is display
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "web-EC2-2"
  }
}




#----------------------------------------------------------------------
# APP SERVERS
#----------------------------------------------------------------------

resource "aws_instance" "app-Server1" {
  ami           = "ami-0b1ebe0bc3c80dc51" # Custom AMI for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  subnet_id              = aws_subnet.app_private_subnet1a.id
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  user_data = templatefile(
    "${path.module}/app-tier.sh",
    {
      mongodb_private_ip = aws_instance.data_server_1.private_ip
      secret_arn         = aws_secretsmanager_secret.app_config.arn
    }
  )


  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "app-EC2"
  }
}


resource "aws_instance" "app-Server2" {
  ami           = "ami-0b1ebe0bc3c80dc51" # Custom AMI for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  subnet_id              = aws_subnet.app_private_subnet1b.id
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  user_data = templatefile(
    "${path.module}/app-tier.sh",
    {
      mongodb_private_ip = aws_instance.data_server_2.private_ip
      secret_arn         = aws_secretsmanager_secret.app_config.arn
    }
  )

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "app-EC2-2"
  }
}



#----------------------------------------------------------------------
# ALL DATA SERVERS
#----------------------------------------------------------------------


resource "aws_instance" "data_server_1" {
  ami           = "ami-0ecb62995f68bb549" # for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  subnet_id              = aws_subnet.data_private_subnet["a"].id
  vpc_security_group_ids = [aws_security_group.db-tier-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name


  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Data-EC2"
  }
}



resource "aws_instance" "data_server_2" {
  ami           = "ami-0ecb62995f68bb549" # for us-east-1
  instance_type = "t3.micro"


  # if we do not specify the vpc subnets info here, the ec2 instance will be situated in the default VPC that came with the account 
  subnet_id              = aws_subnet.data_private_subnet["b"].id
  vpc_security_group_ids = [aws_security_group.db-tier-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name


  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Data-EC2-2"
  }
}




