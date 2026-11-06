# variable "aws_key_pair_name" {          // newly added variable
#   description = "EC2 key pair name"      // Description of the variable
#   type        = string              // Type of the variable
# }

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "attach_ssm" {
  description = "Attach SSM policy to EC2 role"
  type        = bool
  default     = true // newly added default value
}

variable "attach_cloudwatch" {
  description = "Attach CloudWatch policy to EC2 role"
  type        = bool
  default     = true
}
