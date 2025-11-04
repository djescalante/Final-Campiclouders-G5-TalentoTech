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

variable "max_records" {
  description = "Máximo número de registros permitidos en DynamoDB"
  type        = number
  default     = 100
}

# ============================================================================
# VARIABLES DE MONITOREO Y OBSERVABILIDAD
# ============================================================================

variable "alert_email" {
  description = "jde.sistemas@gmail.com" # Email para notificaciones de alarmas
  type        = string
  default     = "jde.sistemas@gmail.com" # Email para notificaciones de alarmas
}

variable "alarm_5xx_threshold" {
  description = "Umbral de errores 5xx para activar alarma"
  type        = number
  default     = 10
}

variable "alarm_latency_threshold" {
  description = "Umbral de latencia P99 en segundos para activar alarma"
  type        = number
  default     = 3.0
}

variable "alarm_cpu_threshold" {
  description = "Umbral de uso de CPU (%) para activar alarma"
  type        = number
  default     = 80
}

variable "alarm_dynamodb_errors_threshold" {
  description = "Umbral de errores de DynamoDB para activar alarma"
  type        = number
  default     = 5
}

variable "alarm_app_error_threshold" {
  description = "Umbral de errores en logs de aplicación para activar alarma"
  type        = number
  default     = 20
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 7
}
