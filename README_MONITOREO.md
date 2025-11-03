# 📊 Extensión de Monitoreo y Observabilidad - CloudWatch

## 🎯 ¿Qué se ha agregado?

Este proyecto ahora incluye un **sistema completo de monitoreo y observabilidad** implementado con Terraform, que incluye:

### ✨ Características Principales

1. **Dashboard de CloudWatch** 📊
   - Visualización en tiempo real de todas las métricas clave
   - 4 secciones organizadas (Salud, HTTP, Infraestructura, DynamoDB)
   - Widgets interactivos y personalizables

2. **7 Alarmas Configuradas** 🚨
   - Errores 5xx del servidor
   - Alta latencia (P99)
   - Instancias no saludables
   - Alto uso de CPU
   - Salud del ambiente degradada
   - Errores en DynamoDB
   - Errores en logs de aplicación

3. **Sistema de Notificaciones** 📧
   - SNS Topic para alertas
   - Integración con email
   - Fácil extensión a Slack, PagerDuty, etc.

4. **Logs Centralizados** 📝
   - CloudWatch Log Group
   - Retención configurable
   - Métricas personalizadas desde logs

---

## 🚀 Inicio Rápido

### 1. Configurar Email de Alertas

Edita `terraform.tfvars` (tu archivo real, NO el .example):

```hcl
# Cambiar de:
alert_email = ""

# A:
alert_email = "tu-email-real@ejemplo.com"
```

🔒 **Importante**: `terraform.tfvars` NO se sube a GitHub (protegido por .gitignore)

### 2. Ajustar Umbrales (Opcional)

```hcl
alarm_5xx_threshold              = 10    # Errores 5xx
alarm_latency_threshold          = 3.0   # Segundos
alarm_cpu_threshold              = 80    # Porcentaje
alarm_dynamodb_errors_threshold  = 5     # Errores
alarm_app_error_threshold        = 20    # Errores en logs
log_retention_days               = 7     # Días
```

### 3. Desplegar

```bash
terraform init
terraform plan
terraform apply
```

### 4. Confirmar Suscripción

Revisa tu email y confirma la suscripción a las notificaciones de AWS.

### 5. Acceder al Dashboard

Después del `terraform apply`, copia la URL del output:

```bash
cloudwatch_dashboard_url = "https://console.aws.amazon.com/cloudwatch/..."
```

---

## 📁 Archivos Nuevos

```
proyecto/
├── monitoring.tf                 # ⭐ Recursos de monitoreo
├── docs/
│   └── GUIA_MONITOREO.md        # ⭐ Guía completa de monitoreo
└── test_alarms.sh               # ⭐ Script para probar alarmas
```

### Archivos Modificados

```
proyecto/
├── variables.tf                 # ✏️ Variables de monitoreo añadidas
├── outputs.tf                   # ✏️ Outputs de monitoreo añadidos
└── terraform.tfvars.example     # ✏️ Ejemplo actualizado
```

---

## 📊 Dashboard de CloudWatch

El dashboard muestra:

### Fila 1: Salud General
- **Salud del Ambiente**: Indicador 0-25 del estado de Elastic Beanstalk
- **Estado de Instancias**: Instancias OK, degradadas y severas

### Fila 2: Métricas HTTP
- **Respuestas HTTP**: 2xx, 4xx, 5xx
- **Latencia**: P50, P90, P99

### Fila 3: Infraestructura
- **CPU**: Uso promedio
- **Red**: Tráfico de entrada/salida
- **Status Checks**: Verificaciones de salud

### Fila 4: DynamoDB
- **Capacidad**: RCU y WCU consumidas
- **Errores**: Errores de usuario y sistema

---

## 🚨 Alarmas Configuradas

| Alarma | Dispara cuando | Acción recomendada |
|--------|----------------|-------------------|
| **high-5xx-errors** | > 10 errores 5xx en 10 min | Revisar logs de aplicación |
| **high-latency** | P99 > 3 segundos | Optimizar queries a DynamoDB |
| **unhealthy-instances** | < 1 instancia saludable | Revisar health checks y logs |
| **high-cpu** | CPU > 80% | Escalar o optimizar código |
| **environment-degraded** | Salud > 15 | Revisar dashboard completo |
| **dynamodb-errors** | > 5 errores en 5 min | Verificar permisos IAM |
| **application-errors** | > 20 errores en logs | Revisar logs de aplicación |

---

## 🔧 Personalización

### Cambiar Umbrales de Alarmas

Edita `terraform.tfvars`:

```hcl
# Más estricto (producción)
alarm_5xx_threshold = 5
alarm_latency_threshold = 1.0

# Más permisivo (desarrollo)
alarm_5xx_threshold = 50
alarm_latency_threshold = 5.0
```

### Añadir Más Widgets al Dashboard

Edita `monitoring.tf` y añade widgets dentro del `dashboard_body`:

```hcl
{
  type = "metric"
  properties = {
    metrics = [
      ["AWS/DynamoDB", "SuccessfulRequestLatency", 
       { stat = "Average", label = "Latencia DDB" }]
    ]
    view    = "timeSeries"
    region  = var.region
    title   = "🚀 Nueva Métrica"
    period  = 300
  }
  width  = 12
  height = 6
  x      = 0
  y      = 24  # Posición en el dashboard
}
```

### Añadir Suscriptores al SNS

**Por Email (Terraform)**:
```hcl
resource "aws_sns_topic_subscription" "email_alerts_2" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "otro-email@ejemplo.com"
}
```

**Por CLI**:
```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint otro-email@ejemplo.com
```

### Integrar con Slack

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol https \
  --notification-endpoint https://hooks.slack.com/services/YOUR/WEBHOOK
```

---

## 🧪 Probar las Alarmas

Usa el script `test_alarms.sh`:

```bash
# Hacer el script ejecutable
chmod +x test_alarms.sh

# Ejecutar en modo interactivo
./test_alarms.sh

# O ejecutar prueba específica
./test_alarms.sh 5xx
./test_alarms.sh latency
./test_alarms.sh status
```

### Prueba Manual de Alarmas

**1. Probar alarma de 5xx:**
```bash
# Generar peticiones a endpoint inexistente
for i in {1..50}; do
  curl "https://$(terraform output -raw eb_environment_cname)/no-existe"
done
```

**2. Probar alarma de latencia:**
```bash
# Enviar muchas peticiones concurrentes
for i in {1..100}; do
  curl "https://$(terraform output -raw eb_environment_cname)/" &
done
```

**3. Ver estado de alarmas:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "EB-Dynamo" \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' \
  --output table
```

---

## 📝 Ver Logs

### En Tiempo Real

```bash
# Seguir logs en vivo
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow

# Filtrar errores
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --follow
```

### Logs Históricos

```bash
# Últimas 1000 líneas
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --since 1h

# Buscar patrón específico
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --max-items 50
```

---

## 📊 Consultar Métricas

### Ver Métricas de Elastic Beanstalk

```bash
# Errores 5xx en la última hora
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name ApplicationRequests5xx \
  --dimensions Name=EnvironmentName,Value=eb-dynamo-env \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Ver Métricas de DynamoDB

```bash
# Capacidad consumida
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=ContactosCampiclouders \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

---

## 💰 Costos Estimados

### CloudWatch

| Componente | Cantidad | Costo Mensual Aprox. |
|------------|----------|---------------------|
| Dashboard | 1 | $3.00 |
| Alarmas | 7 | $0.70 (primeras 10 gratis) |
| Log Ingestion | 1 GB | $0.50 |
| Log Storage | 1 GB × 7 días | $0.03 |
| **TOTAL** | | **~$4.23/mes** |

> **Nota**: Los primeros 10 dashboards y 10 alarmas son gratis con AWS Free Tier

### Optimizar Costos

```hcl
# Reducir retención de logs
log_retention_days = 3  # En lugar de 7

# Reducir número de alarmas (comentar las menos críticas)
# resource "aws_cloudwatch_metric_alarm" "application_errors" { ... }
```

---

## 🔍 Troubleshooting

### No recibo notificaciones por email

1. Verifica que confirmaste la suscripción
2. Revisa spam/correo no deseado
3. Verifica la suscripción:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

### El dashboard no muestra datos

1. Espera 5-10 minutos después del deploy
2. Genera tráfico a la aplicación
3. Verifica que la aplicación esté corriendo:
```bash
curl https://$(terraform output -raw eb_environment_cname)
```

### Las alarmas se activan constantemente

Ajusta los umbrales en `terraform.tfvars`:
```hcl
alarm_5xx_threshold = 50      # Aumentar
alarm_latency_threshold = 10.0  # Aumentar
```

---

## 📚 Documentación Adicional

- **[GUIA_MONITOREO.md](docs/GUIA_MONITOREO.md)**: Guía completa y detallada
- **[GUIA_TERRAFORM_COMPLETA.md](docs/GUIA_TERRAFORM_COMPLETA.md)**: Documentación de Terraform
- **[AWS CloudWatch Docs](https://docs.aws.amazon.com/cloudwatch/)**
- **[Elastic Beanstalk Health](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html)**

---

## 🎓 Mejores Prácticas

### 1. Ajusta umbrales según el ambiente

```hcl
# Desarrollo
alarm_5xx_threshold = 50
alarm_latency_threshold = 5.0

# Producción
alarm_5xx_threshold = 5
alarm_latency_threshold = 1.0
```

### 2. Usa tags consistentes

Todos los recursos tienen tags automáticos:
```hcl
tags = {
  Name        = "${var.app_name}-resource"
  Environment = var.env_name
}
```

### 3. Estructura tus logs

En tu aplicación Node.js:
```javascript
console.log(JSON.stringify({
  timestamp: new Date().toISOString(),
  level: 'INFO',
  message: 'Contact created',
  contactId: '123'
}));
```

### 4. Monitorea los costos

```bash
# Ver costos de CloudWatch
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost"
```

---

## 🚀 Próximos Pasos

Para extender aún más el monitoreo:

1. **AWS X-Ray**: Tracing distribuido
2. **Container Insights**: Si migras a ECS
3. **CloudWatch Synthetics**: Monitoreo sintético
4. **AWS Config**: Compliance y auditoría
5. **Cost Anomaly Detection**: Alertas de costos

---

## 📞 Soporte

Si tienes preguntas o encuentras problemas:

1. Revisa la [Guía de Monitoreo](docs/GUIA_MONITOREO.md)
2. Consulta los [logs](#-ver-logs)
3. Verifica el [estado de las alarmas](#probar-las-alarmas)

---

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

**Hecho con ❤️ para monitoreo empresarial en AWS**
