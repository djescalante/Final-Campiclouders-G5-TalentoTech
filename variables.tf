variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "ContactosCampiclouders"
}

variable "app_name" {
  description = "Elastic Beanstalk application name"
  type        = string
  default     = "EB-Dynamo"
}

variable "env_name" {
  description = "Elastic Beanstalk environment name"
  type        = string
  default     = "eb-dynamo-env"
}

variable "cors_origin" {
  description = "CORS origin for the API"
  type        = string
  default     = "*"
}

variable "instance_type" {
  description = "EC2 instance type for EB"
  type        = string
  default     = "t3.micro"
}

variable "eb_ec2_role_name" {
  description = "Name for the EB EC2 instance role. If empty, a name will be derived from the app_name."
  type        = string
  default     = "" # Dejar vacío para que se genere un nombre único.
}

variable "eb_instance_profile_name" {
  description = "Name for the IAM Instance Profile. If empty, it will be derived from eb_ec2_role_name."
  type        = string
  default     = ""
}

variable "solution_stack_name" {
  description = "[DEPRECADO] Solo para LocalStack/AL2. Usa platform_arn en AWS real."
  type        = string
  default     = ""
}
