# 🛠️ Comandos CLI Útiles - Monitoreo CloudWatch

Este documento contiene todos los comandos CLI que necesitas para gestionar y monitorear tu infraestructura.

---

## 📊 CloudWatch Dashboard

### Ver Dashboards Disponibles
```bash
aws cloudwatch list-dashboards
```

### Ver Dashboard Específico
```bash
aws cloudwatch get-dashboard \
  --dashboard-name EB-Dynamo-dashboard
```

### Exportar Dashboard (Backup)
```bash
aws cloudwatch get-dashboard \
  --dashboard-name EB-Dynamo-dashboard > dashboard-backup.json
```

### Restaurar Dashboard
```bash
aws cloudwatch put-dashboard \
  --dashboard-name EB-Dynamo-dashboard \
  --dashboard-body file://dashboard-backup.json
```

### Eliminar Dashboard
```bash
aws cloudwatch delete-dashboards \
  --dashboard-names EB-Dynamo-dashboard
```

---

## 🚨 CloudWatch Alarmas

### Listar Todas las Alarmas
```bash
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

### Listar Alarmas del Proyecto
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "EB-Dynamo" \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' \
  --output table
```

### Ver Alarmas Activas (ALARM)
```bash
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table
```

### Ver Detalles de una Alarma Específica
```bash
aws cloudwatch describe-alarms \
  --alarm-names EB-Dynamo-high-5xx-errors
```

### Historial de una Alarma
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --max-records 10 \
  --output table
```

### Activar Alarma Manualmente (Prueba)
```bash
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value ALARM \
  --state-reason "Manual test"
```

### Desactivar Alarma (Volver a OK)
```bash
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value OK \
  --state-reason "Test completed"
```

### Deshabilitar Alarma Temporalmente
```bash
aws cloudwatch disable-alarm-actions \
  --alarm-names EB-Dynamo-high-5xx-errors
```

### Re-habilitar Alarma
```bash
aws cloudwatch enable-alarm-actions \
  --alarm-names EB-Dynamo-high-5xx-errors
```

### Eliminar Alarma
```bash
aws cloudwatch delete-alarms \
  --alarm-names EB-Dynamo-high-5xx-errors
```

---

## 📝 CloudWatch Logs

### Listar Log Groups
```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/elasticbeanstalk/EB-Dynamo"
```

### Ver Logs en Tiempo Real
```bash
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow
```

### Ver Últimos Logs (Sin Seguir)
```bash
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --since 1h
```

### Filtrar Logs por Patrón
```bash
# Buscar errores
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --follow

# Buscar palabra específica
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "DynamoDB" \
  --since 30m
```

### Buscar en Logs Históricos
```bash
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --max-items 50
```

### Ver Log Streams
```bash
aws logs describe-log-streams \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --order-by LastEventTime \
  --descending \
  --max-items 10
```

### Exportar Logs
```bash
# Crear tarea de exportación (a S3)
aws logs create-export-task \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --from $(date -d '1 day ago' +%s)000 \
  --to $(date +%s)000 \
  --destination your-bucket-name \
  --destination-prefix logs/
```

### Ver Metric Filters
```bash
aws logs describe-metric-filters \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env
```

### Cambiar Retención de Logs
```bash
# 7 días
aws logs put-retention-policy \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --retention-in-days 7

# 30 días
aws logs put-retention-policy \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --retention-in-days 30
```

### Eliminar Log Group
```bash
aws logs delete-log-group \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env
```

---

## 📈 CloudWatch Métricas

### Obtener Métricas Disponibles
```bash
# Elastic Beanstalk
aws cloudwatch list-metrics \
  --namespace AWS/ElasticBeanstalk \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env

# DynamoDB
aws cloudwatch list-metrics \
  --namespace AWS/DynamoDB \
  --dimensions Name=TableName,Value=ContactosCampiclouders

# EC2
aws cloudwatch list-metrics \
  --namespace AWS/EC2
```

### Ver Estadísticas de Métrica

**Errores 5xx (Última hora):**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name ApplicationRequests5xx \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

**Latencia P99 (Última hora):**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name ApplicationLatencyP99 \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

**Uso de CPU (Última hora):**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

**DynamoDB Capacidad Consumida:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=ContactosCampiclouders \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Publicar Métrica Personalizada
```bash
aws cloudwatch put-metric-data \
  --namespace MyApp/Custom \
  --metric-name ContactsCreated \
  --value 1 \
  --timestamp $(date -u +%Y-%m-%dT%H:%M:%S)
```

### Ver Datos de Métrica (Query)
```bash
aws cloudwatch get-metric-data \
  --metric-data-queries '[
    {
      "Id": "m1",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/ElasticBeanstalk",
          "MetricName": "ApplicationRequests5xx",
          "Dimensions": [{"Name":"EnvironmentName","Value":"eb-dynamo-env"}]
        },
        "Period": 300,
        "Stat": "Sum"
      }
    }
  ]' \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S)
```

---

## 📧 SNS (Notificaciones)

### Listar Topics
```bash
aws sns list-topics \
  --query 'Topics[?contains(TopicArn, `EB-Dynamo`)]'
```

### Ver Detalles del Topic
```bash
aws sns get-topic-attributes \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

### Listar Suscripciones
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

### Añadir Suscripción por Email
```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint nuevo-email@ejemplo.com
```

### Añadir Suscripción por SMS
```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol sms \
  --notification-endpoint +1234567890
```

### Añadir Suscripción HTTPS (Slack)
```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol https \
  --notification-endpoint https://hooks.slack.com/services/YOUR/WEBHOOK
```

### Eliminar Suscripción
```bash
# Primero obtener el ARN de la suscripción
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Luego eliminar
aws sns unsubscribe \
  --subscription-arn arn:aws:sns:us-east-1:123456789012:EB-Dynamo-alerts:UUID
```

### Publicar Mensaje de Prueba
```bash
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --message "Test notification from CLI" \
  --subject "Test Alert"
```

### Confirmar Suscripción (Si tienes el token)
```bash
aws sns confirm-subscription \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --token "TOKEN_FROM_EMAIL"
```

---

## 🎯 Elastic Beanstalk

### Ver Salud del Ambiente
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name eb-dynamo-env \
  --attribute-names All
```

### Ver Salud de Instancias
```bash
aws elasticbeanstalk describe-instances-health \
  --environment-name eb-dynamo-env \
  --attribute-names All
```

### Ver Eventos Recientes
```bash
aws elasticbeanstalk describe-events \
  --environment-name eb-dynamo-env \
  --max-records 20
```

### Ver Eventos de Error
```bash
aws elasticbeanstalk describe-events \
  --environment-name eb-dynamo-env \
  --severity ERROR \
  --max-records 10
```

### Ver Configuración del Ambiente
```bash
aws elasticbeanstalk describe-configuration-settings \
  --environment-name eb-dynamo-env \
  --application-name EB-Dynamo
```

### Ver Recursos del Ambiente
```bash
aws elasticbeanstalk describe-environment-resources \
  --environment-name eb-dynamo-env
```

---

## 💾 DynamoDB

### Ver Información de la Tabla
```bash
aws dynamodb describe-table \
  --table-name ContactosCampiclouders
```

### Ver Métricas de la Tabla
```bash
aws dynamodb describe-table \
  --table-name ContactosCampiclouders \
  --query 'Table.[TableName,ItemCount,TableSizeBytes]'
```

### Escanear Items (¡Cuidado en producción!)
```bash
aws dynamodb scan \
  --table-name ContactosCampiclouders \
  --limit 10
```

### Contar Items
```bash
aws dynamodb scan \
  --table-name ContactosCampiclouders \
  --select COUNT
```

---

## 💰 Costos y Billing

### Ver Costos de CloudWatch (Mes Actual)
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://filter-cloudwatch.json
```

Crear `filter-cloudwatch.json`:
```json
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon CloudWatch"]
  }
}
```

### Ver Costos de Todos los Servicios
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Forecast de Costos
```bash
aws ce get-cost-forecast \
  --time-period Start=$(date +%Y-%m-%d),End=$(date -d "+30 days" +%Y-%m-%d) \
  --metric UNBLENDED_COST \
  --granularity MONTHLY
```

---

## 🔍 Búsquedas Útiles

### Buscar Errores 5xx en Logs
```bash
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "[time, request, status=5*, ...]" \
  --max-items 20
```

### Buscar Requests Lentos
```bash
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "[..., duration > 3000]" \
  --max-items 20
```

### Buscar Errores de DynamoDB
```bash
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "DynamoDB ERROR" \
  --max-items 20
```

---

## 📊 Scripts Útiles

### Script: Resumen de Salud
```bash
#!/bin/bash
# health-summary.sh

echo "=== ELASTIC BEANSTALK ==="
aws elasticbeanstalk describe-environment-health \
  --environment-name eb-dynamo-env \
  --attribute-names Status,Color \
  --query '[EnvironmentName,Status,Color]' \
  --output table

echo "=== ALARMAS ACTIVAS ==="
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --alarm-name-prefix "EB-Dynamo" \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table

echo "=== ÚLTIMOS ERRORES EN LOGS ==="
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --max-items 5 \
  --query 'events[*].message' \
  --output text
```

### Script: Monitor Continuo
```bash
#!/bin/bash
# monitor.sh

while true; do
  clear
  date
  echo "================================"
  echo "ALARMAS:"
  aws cloudwatch describe-alarms \
    --alarm-name-prefix "EB-Dynamo" \
    --query 'MetricAlarms[*].[AlarmName,StateValue]' \
    --output table
  
  echo ""
  echo "SALUD DEL AMBIENTE:"
  aws elasticbeanstalk describe-environment-health \
    --environment-name eb-dynamo-env \
    --attribute-names Status,Color \
    --output table
  
  sleep 60
done
```

### Script: Exportar Todas las Métricas
```bash
#!/bin/bash
# export-metrics.sh

DATE=$(date +%Y%m%d)
OUTPUT_DIR="metrics-$DATE"
mkdir -p "$OUTPUT_DIR"

# Errores 5xx
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name ApplicationRequests5xx \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum > "$OUTPUT_DIR/5xx-errors.json"

# Latencia
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name ApplicationLatencyP99 \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average > "$OUTPUT_DIR/latency.json"

echo "Métricas exportadas a $OUTPUT_DIR/"
```

---

## 🎯 Alias Recomendados

Añadir a `~/.bashrc` o `~/.zshrc`:

```bash
# CloudWatch
alias cw-dash='open $(terraform output -raw cloudwatch_dashboard_url)'
alias cw-logs='aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow'
alias cw-alarms='aws cloudwatch describe-alarms --alarm-name-prefix "EB-Dynamo" --query "MetricAlarms[*].[AlarmName,StateValue]" --output table'
alias cw-errors='aws logs filter-log-events --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --filter-pattern "ERROR" --max-items 20'

# Elastic Beanstalk
alias eb-health='aws elasticbeanstalk describe-environment-health --environment-name eb-dynamo-env --attribute-names All'
alias eb-events='aws elasticbeanstalk describe-events --environment-name eb-dynamo-env --max-records 20'

# SNS
alias sns-test='aws sns publish --topic-arn $(terraform output -raw sns_topic_arn) --message "Test from CLI" --subject "Test Alert"'

# General
alias tf-out='terraform output'
```

---

## 🔄 Comandos de Mantenimiento

### Backup Completo
```bash
#!/bin/bash
# backup-monitoring.sh

BACKUP_DIR="backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Dashboard
aws cloudwatch get-dashboard \
  --dashboard-name EB-Dynamo-dashboard > "$BACKUP_DIR/dashboard.json"

# Alarmas
aws cloudwatch describe-alarms \
  --alarm-name-prefix "EB-Dynamo" > "$BACKUP_DIR/alarms.json"

# SNS Topic
aws sns get-topic-attributes \
  --topic-arn $(terraform output -raw sns_topic_arn) > "$BACKUP_DIR/sns-topic.json"

# Suscripciones
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) > "$BACKUP_DIR/subscriptions.json"

echo "Backup completado en $BACKUP_DIR/"
```

---

**💡 Tip:** Guarda este archivo como referencia y crea aliases para los comandos que uses más frecuentemente.
