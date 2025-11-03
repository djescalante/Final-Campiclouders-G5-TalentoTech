output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.contacts.arn
  description = "ARN of the DynamoDB table"
}

output "eb_environment_cname" {
  value       = aws_elastic_beanstalk_environment.env.cname
  description = "CNAME of the EB environment"
}

# ============================================================================
# OUTPUTS DE MONITOREO Y OBSERVABILIDAD
# ============================================================================

output "cloudwatch_dashboard_name" {
  value       = aws_cloudwatch_dashboard.main.dashboard_name
  description = "Nombre del Dashboard de CloudWatch"
}

output "cloudwatch_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
  description = "URL del Dashboard de CloudWatch"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "ARN del Topic SNS para alarmas"
}

output "cloudwatch_log_group" {
  value       = aws_cloudwatch_log_group.application.name
  description = "Nombre del Log Group de CloudWatch"
}

output "alarms_created" {
  value = {
    http_5xx              = aws_cloudwatch_metric_alarm.http_5xx.alarm_name
    high_latency          = aws_cloudwatch_metric_alarm.high_latency.alarm_name
    unhealthy_instances   = aws_cloudwatch_metric_alarm.unhealthy_instances.alarm_name
    high_cpu              = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    environment_health    = aws_cloudwatch_metric_alarm.environment_health.alarm_name
    dynamodb_errors       = aws_cloudwatch_metric_alarm.dynamodb_errors.alarm_name
    application_errors    = aws_cloudwatch_metric_alarm.application_errors.alarm_name
  }
  description = "Nombres de todas las alarmas creadas"
}