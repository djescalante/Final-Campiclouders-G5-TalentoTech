# Ejemplos de Notificaciones de Alarmas

## 📧 Email de Alarma Activada

```
Subject: ALARM: "EB-Dynamo-high-5xx-errors" in US East (N. Virginia)

You are receiving this email because your Amazon CloudWatch Alarm "EB-Dynamo-high-5xx-errors" 
in the US East (N. Virginia) region has entered the ALARM state, 
because "Threshold Crossed: 1 out of the last 1 datapoints [15.0 (05/11/24 14:23:00)] 
was greater than the threshold (10.0) (minimum 1 datapoint for OK -> ALARM transition)." 
at "Sunday 05 November, 2024 14:28:29 UTC".

View this alarm in the AWS Management Console:
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:alarm/EB-Dynamo-high-5xx-errors

Alarm Details:
- Name:                       EB-Dynamo-high-5xx-errors
- Description:                Alerta cuando hay más de 10 errores 5xx en 10 minutos
- State Change:               OK -> ALARM
- Reason for State Change:    Threshold Crossed: 15 errors detected
- Timestamp:                  Sunday, 05 November, 2024 14:28:29 UTC
- AWS Account:                123456789012
- Alarm Arn:                  arn:aws:cloudwatch:us-east-1:123456789012:alarm:EB-Dynamo-high-5xx-errors

Threshold:
- The alarm is in the ALARM state when the metric is GreaterThanThreshold 10.0 for 300 seconds. 

Monitored Metric:
- MetricNamespace:                     AWS/ElasticBeanstalk
- MetricName:                          ApplicationRequests5xx
- Dimensions:                          [EnvironmentName = eb-dynamo-env]
- Period:                              300 seconds
- Statistic:                           Sum
- Unit:                                not specified
- TreatMissingData:                    notBreaching

State Change Actions:
- OK: arn:aws:sns:us-east-1:123456789012:EB-Dynamo-alerts
- ALARM: arn:aws:sns:us-east-1:123456789012:EB-Dynamo-alerts
- INSUFFICIENT_DATA: 
```

---

## 📧 Email de Alarma Resuelta (OK)

```
Subject: OK: "EB-Dynamo-high-5xx-errors" in US East (N. Virginia)

You are receiving this email because your Amazon CloudWatch Alarm "EB-Dynamo-high-5xx-errors" 
in the US East (N. Virginia) region has returned to the OK state at 
"Sunday 05 November, 2024 14:43:29 UTC".

View this alarm in the AWS Management Console:
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:alarm/EB-Dynamo-high-5xx-errors

Alarm Details:
- Name:                       EB-Dynamo-high-5xx-errors
- Description:                Alerta cuando hay más de 10 errores 5xx en 10 minutos
- State Change:               ALARM -> OK
- Reason for State Change:    Threshold Crossed: 3 errors (below threshold)
- Timestamp:                  Sunday, 05 November, 2024 14:43:29 UTC
```

---

## 💬 Slack Notification (Ejemplo)

```
🚨 CloudWatch Alarm TRIGGERED

Alarm: EB-Dynamo-high-latency
Environment: eb-dynamo-env
Region: us-east-1

📊 Details:
• Metric: ApplicationLatencyP99
• Current Value: 4.23 seconds
• Threshold: 3.0 seconds
• Time: 2024-11-05 14:30:00 UTC

⚠️ Action Required:
Check application performance and database queries

🔗 View Dashboard: https://console.aws.amazon.com/cloudwatch/...
```

---

## 📱 SMS Notification (Ejemplo)

```
AWS CloudWatch ALARM: EB-Dynamo-unhealthy-instances
Environment: eb-dynamo-env has 0 healthy instances.
View: https://console.aws.amazon.com/elasticbeanstalk/
```

---

## 📊 Formato JSON de Notificación SNS

Útil para integraciones personalizadas (Lambda, Webhooks):

```json
{
  "AlarmName": "EB-Dynamo-high-5xx-errors",
  "AlarmDescription": "Alerta cuando hay más de 10 errores 5xx en 10 minutos",
  "AWSAccountId": "123456789012",
  "NewStateValue": "ALARM",
  "NewStateReason": "Threshold Crossed: 1 out of the last 1 datapoints [15.0 (05/11/24 14:23:00)] was greater than the threshold (10.0)",
  "StateChangeTime": "2024-11-05T14:28:29.123+0000",
  "Region": "US East (N. Virginia)",
  "AlarmArn": "arn:aws:cloudwatch:us-east-1:123456789012:alarm:EB-Dynamo-high-5xx-errors",
  "OldStateValue": "OK",
  "Trigger": {
    "MetricName": "ApplicationRequests5xx",
    "Namespace": "AWS/ElasticBeanstalk",
    "StatisticType": "Statistic",
    "Statistic": "SUM",
    "Unit": null,
    "Dimensions": [
      {
        "value": "eb-dynamo-env",
        "name": "EnvironmentName"
      }
    ],
    "Period": 300,
    "EvaluationPeriods": 2,
    "ComparisonOperator": "GreaterThanThreshold",
    "Threshold": 10.0,
    "TreatMissingData": "notBreaching",
    "EvaluateLowSampleCountPercentile": ""
  }
}
```

---

## 🔔 Tipos de Notificaciones por Alarma

### 1. high-5xx-errors
```
🚨 ALARM: Server Errors Detected

Metric: ApplicationRequests5xx
Current: 15 errors
Threshold: 10 errors
Period: Last 10 minutes

Action: Check application logs immediately
Priority: HIGH
```

### 2. high-latency
```
⏱️ ALARM: High Latency Detected

Metric: ApplicationLatencyP99
Current: 4.5 seconds
Threshold: 3.0 seconds
Period: Last 5 minutes

Action: Review database queries and optimization
Priority: MEDIUM
```

### 3. unhealthy-instances
```
🖥️ ALARM: Instance Health Critical

Metric: InstancesOk
Current: 0 healthy instances
Threshold: < 1 instance
Period: Last 1 minute

Action: IMMEDIATE - Service disruption possible
Priority: CRITICAL
```

### 4. high-cpu
```
💻 ALARM: High CPU Usage

Metric: CPUUtilization
Current: 87%
Threshold: 80%
Period: Last 5 minutes

Action: Consider scaling or optimization
Priority: MEDIUM
```

### 5. environment-degraded
```
🏥 ALARM: Environment Health Degraded

Metric: EnvironmentHealth
Current: 18 (Warning)
Threshold: 15
Scale: 0-10=OK, 10-15=Info, 15-20=Warning, 20-25=Severe
Period: Last 1 minute

Action: Review all system metrics
Priority: HIGH
```

### 6. dynamodb-errors
```
📚 ALARM: DynamoDB Errors

Metric: UserErrors
Current: 7 errors
Threshold: 5 errors
Period: Last 5 minutes

Action: Check IAM permissions and query syntax
Priority: HIGH
```

### 7. application-errors
```
📝 ALARM: Application Errors in Logs

Metric: ErrorCount (Custom)
Current: 25 errors
Threshold: 20 errors
Period: Last 5 minutes

Action: Review application logs for stack traces
Priority: MEDIUM
```

---

## 🎬 Flujo Típico de una Alarma

### 1. Estado Normal (OK)
```
✅ All systems operational
   Last checked: 2024-11-05 14:00:00
   No alarms triggered
```

### 2. Primer Período de Evaluación
```
⚠️ Monitoring: Potential issue detected
   Value: 12 errors (above threshold of 10)
   Status: Evaluating (1 of 2 periods)
   Waiting for confirmation...
```

### 3. Segundo Período de Evaluación
```
🚨 ALARM TRIGGERED
   Value: 15 errors (above threshold of 10)
   Status: ALARM (2 of 2 periods exceeded)
   Notification sent at: 2024-11-05 14:10:00
```

### 4. Problema en Resolución
```
🔄 Recovering
   Value: 8 errors (below threshold)
   Status: Evaluating recovery (1 of 2 periods)
   Monitoring continues...
```

### 5. Problema Resuelto
```
✅ ALARM RESOLVED
   Value: 3 errors (below threshold)
   Status: OK (2 of 2 periods normal)
   Resolution notification sent at: 2024-11-05 14:25:00
   Total downtime: 15 minutes
```

---

## 📋 Checklist de Respuesta a Alarmas

### Cuando recibes una alarma:

- [ ] **1. Leer el mensaje completo**
  - Identificar qué alarma se activó
  - Verificar el valor actual vs. umbral
  - Anotar la hora de activación

- [ ] **2. Acceder al Dashboard**
  - Abrir el dashboard de CloudWatch
  - Revisar todas las métricas relacionadas
  - Identificar patrones o correlaciones

- [ ] **3. Revisar Logs**
  ```bash
  aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
    --since 30m --follow
  ```

- [ ] **4. Verificar Salud del Sistema**
  ```bash
  aws elasticbeanstalk describe-environment-health \
    --environment-name eb-dynamo-env --attribute-names All
  ```

- [ ] **5. Tomar Acción Correctiva**
  - Según el tipo de alarma
  - Documentar acciones tomadas
  - Verificar que el problema se resuelva

- [ ] **6. Post-Mortem (si es necesario)**
  - Documentar causa raíz
  - Implementar prevención
  - Ajustar umbrales si es necesario

---

## 🛠️ Testing de Notificaciones

### Probar que las notificaciones funcionan:

```bash
# 1. Activar alarma manualmente desde CLI
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value ALARM \
  --state-reason "Manual test of alarm notification"

# 2. Esperar notificación (1-2 minutos)

# 3. Volver a OK
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value OK \
  --state-reason "Test completed successfully"
```

---

## 📞 Escalamiento de Incidentes

### Nivel 1: Notificación Inicial (Email)
- Todos los desarrolladores
- Tiempo de respuesta esperado: 15 minutos

### Nivel 2: Escalamiento (Slack)
- Canal de ops
- Si no se resuelve en 30 minutos

### Nivel 3: Crítico (PagerDuty/SMS)
- Ingeniero de guardia
- Para alarmas críticas (unhealthy instances)

### Configuración de Escalamiento:

```hcl
# En monitoring.tf, para alarmas críticas
resource "aws_cloudwatch_metric_alarm" "unhealthy_instances" {
  # ... configuración existente ...
  
  alarm_actions = [
    aws_sns_topic.alerts.arn,           # Email normal
    aws_sns_topic.critical_alerts.arn   # PagerDuty/SMS
  ]
}
```

---

**Mantén este documento como referencia para entender y responder a las alarmas de CloudWatch.**
