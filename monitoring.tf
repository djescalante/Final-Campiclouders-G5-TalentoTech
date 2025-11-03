# ============================================================================
# MONITOREO Y OBSERVABILIDAD - CLOUDWATCH
# ============================================================================

# -----------------------------
# SNS Topic para Alarmas
# -----------------------------
resource "aws_sns_topic" "alerts" {
  name         = "${var.app_name}-alerts"
  display_name = "Alertas de ${var.app_name}"

  tags = {
    Name        = "${var.app_name}-alerts"
    Environment = var.env_name
  }
}

# Suscripción por email (opcional - requiere confirmación manual)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -----------------------------
# CloudWatch Dashboard
# -----------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Fila 1: Métricas de la Aplicación
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "EnvironmentHealth", { stat = "Average", label = "Salud del Ambiente" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "🏥 Salud del Ambiente EB"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 25
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "InstancesOk", { stat = "Average", label = "Instancias OK" }],
            [".", "InstancesDegraded", { stat = "Average", label = "Instancias Degradadas" }],
            [".", "InstancesSevere", { stat = "Average", label = "Instancias Severas" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "🖥️ Estado de Instancias"
          period  = 300
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },

      # Fila 2: Métricas HTTP
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "ApplicationRequests5xx", { stat = "Sum", label = "Errores 5xx", color = "#d62728" }],
            [".", "ApplicationRequests4xx", { stat = "Sum", label = "Errores 4xx", color = "#ff7f0e" }],
            [".", "ApplicationRequests2xx", { stat = "Sum", label = "Respuestas 2xx", color = "#2ca02c" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "📊 Respuestas HTTP"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "ApplicationLatencyP99", { stat = "Average", label = "Latencia P99" }],
            [".", "ApplicationLatencyP90", { stat = "Average", label = "Latencia P90" }],
            [".", "ApplicationLatencyP50", { stat = "Average", label = "Latencia P50 (Mediana)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "⏱️ Latencia de Aplicación (segundos)"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },

      # Fila 3: Métricas de EC2
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Promedio" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "💻 Uso de CPU (%)"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
        width  = 8
        height = 6
        x      = 0
        y      = 12
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "🌐 Tráfico de Red (bytes)"
          period  = 300
        }
        width  = 8
        height = 6
        x      = 8
        y      = 12
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", { stat = "Sum", label = "Checks Fallidos" }],
            [".", "StatusCheckFailed_Instance", { stat = "Sum", label = "Checks Instancia" }],
            [".", "StatusCheckFailed_System", { stat = "Sum", label = "Checks Sistema" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "✅ Status Checks"
          period  = 300
        }
        width  = 8
        height = 6
        x      = 16
        y      = 12
      },

      # Fila 4: Métricas de DynamoDB
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum", label = "RCU Consumidas" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum", label = "WCU Consumidas" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "📚 DynamoDB - Capacidad Consumida"
          period  = 300
        }
        width  = 12
        height = 6
        x      = 0
        y      = 18
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/DynamoDB", "UserErrors", { stat = "Sum", label = "Errores de Usuario" }],
            [".", "SystemErrors", { stat = "Sum", label = "Errores del Sistema" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "⚠️ DynamoDB - Errores"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 18
      }
    ]
  })
}

# -----------------------------
# Alarma: Errores 5xx
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${var.app_name}-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationRequests5xx"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_5xx_threshold
  alarm_description   = "Alerta cuando hay más de ${var.alarm_5xx_threshold} errores 5xx en 10 minutos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-high-5xx-errors"
    Environment = var.env_name
  }
}

# -----------------------------
# Alarma: Alta Latencia P99
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.app_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationLatencyP99"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_latency_threshold
  alarm_description   = "Alerta cuando la latencia P99 supera ${var.alarm_latency_threshold} segundos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-high-latency"
    Environment = var.env_name
  }
}

# -----------------------------
# Alarma: Instancias No Saludables
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_instances" {
  alarm_name          = "${var.app_name}-unhealthy-instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "InstancesOk"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alerta cuando hay menos de 1 instancia saludable"
  treat_missing_data  = "breaching"

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-unhealthy-instances"
    Environment = var.env_name
  }
}

# -----------------------------
# Alarma: Alto Uso de CPU
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "Alerta cuando el uso de CPU supera ${var.alarm_cpu_threshold}%"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-high-cpu"
    Environment = var.env_name
  }
}

# -----------------------------
# Alarma: Salud del Ambiente Degradada
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "environment_health" {
  alarm_name          = "${var.app_name}-environment-degraded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EnvironmentHealth"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Average"
  threshold           = "15"
  alarm_description   = "Alerta cuando la salud del ambiente está degradada (>15 = Warning, >20 = Severe)"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.env.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-environment-degraded"
    Environment = var.env_name
  }
}

# -----------------------------
# Alarma: Errores en DynamoDB
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  alarm_name          = "${var.app_name}-dynamodb-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_dynamodb_errors_threshold
  alarm_description   = "Alerta cuando hay errores de usuario en DynamoDB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.contacts.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-dynamodb-errors"
    Environment = var.env_name
  }
}

# -----------------------------
# Log Group para Application Logs
# -----------------------------
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/elasticbeanstalk/${var.app_name}/${var.env_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.app_name}-logs"
    Environment = var.env_name
  }
}

# -----------------------------
# Metric Filter: Logs de Error
# -----------------------------
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${var.app_name}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.app_name}/Application"
    value     = "1"
  }
}

# Alarma para el metric filter
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  alarm_name          = "${var.app_name}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "${var.app_name}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_app_error_threshold
  alarm_description   = "Alerta cuando hay más de ${var.alarm_app_error_threshold} errores en logs de aplicación"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${var.app_name}-application-errors"
    Environment = var.env_name
  }
}
