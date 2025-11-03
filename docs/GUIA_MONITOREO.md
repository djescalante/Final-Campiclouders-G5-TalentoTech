# 📊 Guía de Monitoreo y Observabilidad con CloudWatch

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Componentes Implementados](#componentes-implementados)
3. [Configuración Inicial](#configuración-inicial)
4. [Dashboard de CloudWatch](#dashboard-de-cloudwatch)
5. [Alarmas Configuradas](#alarmas-configuradas)
6. [Gestión de Notificaciones](#gestión-de-notificaciones)
7. [Logs y Métricas Personalizadas](#logs-y-métricas-personalizadas)
8. [Troubleshooting](#troubleshooting)
9. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Descripción General

Este módulo de monitoreo proporciona **observabilidad completa** para tu aplicación Node.js + DynamoDB en Elastic Beanstalk, incluyendo:

- ✅ **Dashboard visual** con todas las métricas clave
- 🚨 **7 alarmas** para detectar problemas proactivamente
- 📧 **Notificaciones por email** vía SNS
- 📝 **Logs centralizados** en CloudWatch
- 🔍 **Métricas personalizadas** de errores de aplicación

---

## 🏗️ Componentes Implementados

### 1. CloudWatch Dashboard
Un dashboard interactivo que muestra:
- 🏥 Salud del ambiente Elastic Beanstalk
- 🖥️ Estado de las instancias EC2
- 📊 Respuestas HTTP (2xx, 4xx, 5xx)
- ⏱️ Latencia de la aplicación (P50, P90, P99)
- 💻 Uso de CPU y red
- ✅ Status checks
- 📚 Métricas de DynamoDB (capacidad y errores)

### 2. Alarmas de CloudWatch

| Alarma | Métrica | Umbral | Descripción |
|--------|---------|--------|-------------|
| **high-5xx-errors** | ApplicationRequests5xx | 10 errores/10min | Detecta errores del servidor |
| **high-latency** | ApplicationLatencyP99 | 3 segundos | Latencia elevada |
| **unhealthy-instances** | InstancesOk | < 1 instancia | Instancias no saludables |
| **high-cpu** | CPUUtilization | 80% | Alto uso de CPU |
| **environment-degraded** | EnvironmentHealth | > 15 | Ambiente degradado |
| **dynamodb-errors** | UserErrors | 5 errores/5min | Errores en DynamoDB |
| **application-errors** | ErrorCount | 20 errores/5min | Errores en logs |

### 3. SNS Topic
- Topic para recibir notificaciones
- Suscripción por email (opcional)
- Integrado con todas las alarmas

### 4. CloudWatch Logs
- Log Group centralizado
- Retención configurable (default: 7 días)
- Metric Filter para contar errores

---

## ⚙️ Configuración Inicial

### Paso 1: Configurar Variables

Edita tu archivo `terraform.tfvars`:

```hcl
# Configuración básica
region        = "us-east-1"
app_name      = "EB-Dynamo"
env_name      = "eb-dynamo-env"

# Configuración de monitoreo
alert_email = "tu-email@ejemplo.com"  # ⚠️ IMPORTANTE: Cambia esto

# Umbrales de alarmas (ajusta según necesites)
alarm_5xx_threshold              = 10
alarm_latency_threshold          = 3.0
alarm_cpu_threshold              = 80
alarm_dynamodb_errors_threshold  = 5
alarm_app_error_threshold        = 20
log_retention_days               = 7
```

### Paso 2: Desplegar el Monitoreo

```bash
# Inicializar Terraform (si es primera vez)
terraform init

# Revisar los cambios que se van a aplicar
terraform plan

# Aplicar los cambios
terraform apply

# Confirma con: yes
```

### Paso 3: Confirmar Suscripción al Email

1. Revisa tu correo después del `terraform apply`
2. Busca un email de **AWS Notifications**
3. Haz clic en **"Confirm subscription"**
4. Ya estás listo para recibir alertas

---

## 📊 Dashboard de CloudWatch

### Acceder al Dashboard

Después del `terraform apply`, verás un output con la URL:

```bash
cloudwatch_dashboard_url = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=EB-Dynamo-dashboard"
```

O accede manualmente:

1. Ve a la consola de AWS CloudWatch
2. En el menú lateral, selecciona **Dashboards**
3. Busca `EB-Dynamo-dashboard` (o el nombre de tu app)

### Estructura del Dashboard

El dashboard está organizado en 4 filas:

#### Fila 1: Salud General
- **Salud del Ambiente EB**: Valor de 0-25 (0=OK, >15=Warning, >20=Severe)
- **Estado de Instancias**: Instancias OK, degradadas y severas

#### Fila 2: Métricas HTTP
- **Respuestas HTTP**: 2xx (éxito), 4xx (cliente), 5xx (servidor)
- **Latencia**: P50, P90 y P99

#### Fila 3: Métricas de Infraestructura
- **CPU**: Uso promedio de CPU
- **Red**: Tráfico de entrada y salida
- **Status Checks**: Checks de instancia y sistema

#### Fila 4: Métricas de DynamoDB
- **Capacidad Consumida**: RCU y WCU
- **Errores**: Errores de usuario y sistema

### Personalizar el Dashboard

Para añadir más widgets:

```hcl
# En monitoring.tf, dentro del dashboard_body, añade un nuevo widget:
{
  type = "metric"
  properties = {
    metrics = [
      ["AWS/DynamoDB", "SuccessfulRequestLatency", { stat = "Average" }]
    ]
    view    = "timeSeries"
    stacked = false
    region  = var.region
    title   = "🚀 Latencia de DynamoDB"
    period  = 300
  }
  width  = 12
  height = 6
  x      = 0
  y      = 24
}
```

---

## 🚨 Alarmas Configuradas

### 1. Alarma de Errores 5xx

**Cuándo se activa**: Más de 10 errores 5xx en 10 minutos

**Qué hacer**:
```bash
# 1. Ver logs de la aplicación
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow

# 2. Ver eventos de EB
aws elasticbeanstalk describe-events \
  --environment-name eb-dynamo-env \
  --max-records 20

# 3. Revisar salud del ambiente
aws elasticbeanstalk describe-environment-health \
  --environment-name eb-dynamo-env \
  --attribute-names All
```

**Causas comunes**:
- Error en el código de la aplicación
- Problemas de conexión con DynamoDB
- Falta de permisos IAM
- Timeout en operaciones

### 2. Alarma de Alta Latencia

**Cuándo se activa**: Latencia P99 > 3 segundos

**Qué hacer**:
```bash
# 1. Revisar consultas a DynamoDB
aws dynamodb describe-table --table-name ContactosCampiclouders

# 2. Ver logs de rendimiento
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "duration"

# 3. Revisar métricas de CPU
```

**Causas comunes**:
- Consultas ineficientes a DynamoDB
- Alto tráfico
- Falta de índices en DynamoDB
- Código no optimizado

### 3. Alarma de Instancias No Saludables

**Cuándo se activa**: Menos de 1 instancia saludable

**Qué hacer**:
```bash
# 1. Revisar salud de instancias
aws elasticbeanstalk describe-instances-health \
  --environment-name eb-dynamo-env

# 2. Ver logs de deployment
aws elasticbeanstalk describe-events \
  --environment-name eb-dynamo-env \
  --severity ERROR

# 3. Revisar configuración
```

**Causas comunes**:
- Fallo en health checks
- Error en el despliegue
- Problemas de configuración
- Recursos insuficientes

### 4. Alarma de Alto Uso de CPU

**Cuándo se activa**: CPU > 80%

**Qué hacer**:
```bash
# 1. Escalar verticalmente (cambiar tipo de instancia)
# En terraform.tfvars:
instance_type = "t3.small"  # o t3.medium

# 2. Escalar horizontalmente (añadir instancias)
# En main.tf, cambiar SingleInstance a LoadBalanced
```

**Causas comunes**:
- Alto tráfico
- Procesos intensivos en CPU
- Código no optimizado
- Tipo de instancia muy pequeño

### 5. Alarma de Ambiente Degradado

**Cuándo se activa**: EnvironmentHealth > 15

**Explicación de valores**:
- 0-10: OK (verde)
- 10-15: Info (gris)
- 15-20: Warning (amarillo)
- 20-25: Degraded/Severe (rojo)

**Qué hacer**:
1. Revisar dashboard completo
2. Verificar otras alarmas activas
3. Ver logs y eventos recientes

### 6. Alarma de Errores en DynamoDB

**Cuándo se activa**: Más de 5 errores en DynamoDB

**Qué hacer**:
```bash
# 1. Ver métricas de DynamoDB
aws dynamodb describe-table \
  --table-name ContactosCampiclouders

# 2. Revisar permisos IAM
aws iam get-role-policy \
  --role-name EB-Dynamo-ec2-role \
  --policy-name ddbBasicAccess

# 3. Ver logs de la aplicación
```

**Causas comunes**:
- Falta de permisos
- Throttling por exceder capacidad
- Validación de datos incorrecta
- Conexión de red

### 7. Alarma de Errores de Aplicación

**Cuándo se activa**: Más de 20 errores en logs

**Qué hacer**:
```bash
# Ver los errores recientes
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "[ERROR]" \
  --max-items 50
```

---

## 📧 Gestión de Notificaciones

### Añadir Más Suscriptores

```bash
# Vía CLI
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint otro-email@ejemplo.com

# O vía Terraform - edita monitoring.tf:
resource "aws_sns_topic_subscription" "email_alerts_2" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "otro-email@ejemplo.com"
}
```

### Integrar con Slack

1. Crea un webhook en Slack
2. Añade suscripción HTTPS:

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol https \
  --notification-endpoint https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Integrar con PagerDuty

```hcl
# En monitoring.tf
resource "aws_sns_topic_subscription" "pagerduty" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/YOUR_KEY/enqueue"
}
```

---

## 📝 Logs y Métricas Personalizadas

### Ver Logs en Tiempo Real

```bash
# Seguir logs en vivo
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow

# Filtrar por patrón
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --follow

# Ver logs de un período específico
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "ERROR"
```

### Crear Métricas Personalizadas

Ejemplo: Contar requests por endpoint

```hcl
# En monitoring.tf
resource "aws_cloudwatch_log_metric_filter" "api_requests" {
  name           = "${var.app_name}-api-requests"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request_id, level, msg, method, path]"

  metric_transformation {
    name      = "APIRequests"
    namespace = "${var.app_name}/Application"
    value     = "1"
    dimensions = {
      Method = "$method"
      Path   = "$path"
    }
  }
}
```

### Enviar Métricas desde la Aplicación

```javascript
// En tu aplicación Node.js
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

async function publishMetric(metricName, value) {
  await cloudwatch.putMetricData({
    Namespace: 'MyApp/Custom',
    MetricData: [{
      MetricName: metricName,
      Value: value,
      Unit: 'Count',
      Timestamp: new Date()
    }]
  }).promise();
}

// Uso:
await publishMetric('ContactsCreated', 1);
```

---

## 🔧 Troubleshooting

### No Recibo Emails de Alarmas

**Solución**:
1. Verifica que confirmaste la suscripción
2. Revisa la carpeta de spam
3. Confirma el topic SNS:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

### El Dashboard No Muestra Datos

**Solución**:
1. Espera 5-10 minutos después del deploy
2. Verifica que la aplicación está corriendo
3. Genera tráfico a la aplicación:
```bash
curl https://$(terraform output -raw eb_environment_cname)
```

### Alarmas Constantemente Activadas

**Solución**:
1. Ajusta los umbrales en `terraform.tfvars`
2. Modifica los períodos de evaluación en `monitoring.tf`
3. Ejemplo para hacer alarma menos sensible:
```hcl
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  # ...
  evaluation_periods = "3"  # Cambiar de 2 a 3
  threshold          = 20   # Aumentar de 10 a 20
  # ...
}
```

### Métricas de DynamoDB No Aparecen

**Solución**:
- Las métricas de DynamoDB solo aparecen cuando hay tráfico
- Genera algunas peticiones a la API
- Verifica permisos IAM

---

## 💡 Mejores Prácticas

### 1. Configuración de Umbrales

```hcl
# Desarrollo
alarm_5xx_threshold = 50
alarm_latency_threshold = 5.0

# Producción
alarm_5xx_threshold = 5
alarm_latency_threshold = 1.0
```

### 2. Retención de Logs

```hcl
# Desarrollo: 3-7 días
log_retention_days = 3

# Producción: 30-90 días
log_retention_days = 30
```

### 3. Estructura de Logs

En tu aplicación Node.js:

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      )
    })
  ]
});

// Uso
logger.info('Contact created', { contactId: '123', userId: 'abc' });
logger.error('DynamoDB error', { error: err.message, table: 'Contacts' });
```

### 4. Tags Consistentes

```hcl
# Añadir tags a todos los recursos
tags = {
  Name        = "${var.app_name}-${resource_name}"
  Environment = var.env_name
  Project     = "ContactManager"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
```

### 5. Monitoreo de Costos

```bash
# Ver costos de CloudWatch
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://filter.json

# filter.json
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon CloudWatch"]
  }
}
```

### 6. Backup y Disaster Recovery

```bash
# Exportar dashboard
aws cloudwatch get-dashboard \
  --dashboard-name EB-Dynamo-dashboard > dashboard-backup.json

# Restaurar dashboard
aws cloudwatch put-dashboard \
  --dashboard-name EB-Dynamo-dashboard \
  --dashboard-body file://dashboard-backup.json
```

---

## 📚 Recursos Adicionales

- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [Elastic Beanstalk Health Monitoring](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html)
- [DynamoDB Metrics](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/metrics-dimensions.html)
- [SNS Documentation](https://docs.aws.amazon.com/sns/)

---

## 🎓 Próximos Pasos

1. **Implementar X-Ray**: Para tracing distribuido
2. **Añadir Container Insights**: Si migras a ECS/Fargate
3. **Configurar AWS Config**: Para compliance
4. **Implementar CloudWatch Synthetics**: Para monitoreo sintético
5. **Añadir AWS Personal Health Dashboard**: Para eventos de AWS

---

**¿Preguntas o problemas?** Abre un issue en el repositorio o contacta al equipo de DevOps.
