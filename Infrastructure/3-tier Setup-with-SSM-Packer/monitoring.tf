resource "aws_instance" "monitoring" {
  ami                    = "ami-0a41a5a8f17e4b911"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app_private_subnet1a.id
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "monitoring-server"
  }
}

output "monitoring_instance_id" {
  description = "Use this ID for SSM port forwarding to access Grafana"
  value       = aws_instance.monitoring.id
}

output "monitoring_private_ip" {
  description = "Private IP of monitoring instance"
  value       = aws_instance.monitoring.private_ip
}
