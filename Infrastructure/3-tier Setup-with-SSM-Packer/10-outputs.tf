
output "vpc" {
  value = aws_vpc.three_tier // VPC output
}


output "vpc_id" {
  value = aws_vpc.three_tier.id // VPC ID output
}



# output "public_subnet_ids" {
#   value = values(aws_subnet.web_public_subnet)[*].id  // Public Subnet IDs output
# }

output "public_subnet_ids" { // Public Subnet IDs output
  value = [
    aws_subnet.web_public_subnet1a.id,
    aws_subnet.web_public_subnet1b.id
  ]
}

output "private_subnet_ids" { // Private Subnet IDs output
  value = [
    aws_subnet.app_private_subnet1a.id,
    aws_subnet.app_private_subnet1b.id
  ]
}

output "data_subnet_ids" { // Data Subnet IDs output
  value = [
    aws_subnet.data_private_subnet["a"].id,
    aws_subnet.data_private_subnet["b"].id
  ]
}


# output "public_connection_string" {                         //  ssh to Public server IDs output
#   value = "ssh -i ~/DevOps/DEPLOYED-PROJECT/Keypairs/Textkey2.pem ubuntu@${aws_instance.Jump-Server.public_ip}"
# }


# output "app_private_subnet_connections" {                               //    ssh to Private server IDs output
#   value = [
#     "ssh -i /home/ubuntu/Textkey2.pem ubuntu@${aws_instance.app-Server1.private_ip}",
#     "ssh -i /home/ubuntu/Textkey2.pem ubuntu@${aws_instance.app-Server2.private_ip}"
#   ]
# }