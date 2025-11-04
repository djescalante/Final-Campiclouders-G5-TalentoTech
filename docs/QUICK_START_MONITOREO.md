# 🚀 Quick Start - Monitoreo CloudWatch

## ⚡ Inicio en 5 Minutos

### 1️⃣ Configurar Email (30 segundos)

```bash
# Editar terraform.tfvars (tu archivo real, NO el .example)
code terraform.tfvars
```

Cambia la línea vacía por tu email real:
```hcl
# De esto:
alert_email = ""

# A esto:
alert_email = "tu-email-real@ejemplo.com"
```

🔒 **Nota**: Este archivo NO se sube a GitHub (protegido por .gitignore)

### 2️⃣ Desplegar (2 minutos)

```bash
terraform apply
# Escribe: yes
```

### 3️⃣ Confirmar Email (1 minuto)

1. Abre tu email
2. Busca "AWS Notification - Subscription Confirmation"
3. Click en "Confirm subscription"

### 4️⃣ Acceder al Dashboard (30 segundos)

```bash
# Copiar y abrir la URL
terraform output cloudwatch_dashboard_url
```

### 5️⃣ Probar Alarma (1 minuto)

```bash
chmod +x test_alarms.sh
./test_alarms.sh
# Opción 1: Errores 5xx
```

---

## 🎯 ¿Qué Tienes Ahora?

### ✅ Dashboard con 12 Métricas
- Salud del ambiente
- Errores HTTP
- Latencia
- CPU y Red
- DynamoDB

### ✅ 7 Alarmas Configuradas
- Errores 5xx > 10
- Latencia > 3s
- CPU > 80%
- Instancias no saludables
- DynamoDB errores
- Ambiente degradado
- Errores en logs

### ✅ Notificaciones por Email
- Cuando se activa una alarma
- Cuando se resuelve
- Con detalles completos

---

## 🔥 Accesos Rápidos

### Ver Dashboard
```bash
# URL directa
terraform output cloudwatch_dashboard_url

# O manualmente:
# AWS Console → CloudWatch → Dashboards → EB-Dynamo-dashboard
```

### Ver Logs en Vivo
```bash
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow
```

### Ver Estado de Alarmas
```bash
./test_alarms.sh
# Opción 5: Ver estado actual
```

### Probar Notificación
```bash
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value ALARM \
  --state-reason "Prueba de notificación"
```

---

## 📊 Acceso al Dashboard

**Opción 1: Desde Terraform**
```bash
terraform output cloudwatch_dashboard_url
```

**Opción 2: Consola AWS**
1. AWS Console
2. CloudWatch
3. Dashboards
4. Buscar: `EB-Dynamo-dashboard`

**Opción 3: URL Directa**
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=EB-Dynamo-dashboard
```

---

## 🚨 Cuando Recibes una Alarma

### Paso 1: Lee el Email
- ¿Qué alarma se activó?
- ¿Cuál es el valor actual?
- ¿Cuál es el umbral?

### Paso 2: Abre el Dashboard
```bash
# Copiar URL del output
terraform output cloudwatch_dashboard_url
```

### Paso 3: Revisa los Logs
```bash
# Ver últimos logs
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --since 30m --follow
```

### Paso 4: Toma Acción

**Para Errores 5xx:**
```bash
# Ver errores recientes
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "ERROR" \
  --max-items 20
```

**Para Alta Latencia:**
```bash
# Revisar métricas de DynamoDB
aws dynamodb describe-table --table-name ContactosCampiclouders
```

**Para CPU Alto:**
```bash
# Escalar a instancia más grande
# En terraform.tfvars cambiar:
instance_type = "t3.small"  # o t3.medium
# Luego: terraform apply
```

---

## 🎨 Personalizar Umbrales

### Para Desarrollo (más permisivo)
```hcl
# En terraform.tfvars
alarm_5xx_threshold = 50
alarm_latency_threshold = 10.0
alarm_cpu_threshold = 90
```

### Para Producción (más estricto)
```hcl
# En terraform.tfvars
alarm_5xx_threshold = 5
alarm_latency_threshold = 1.0
alarm_cpu_threshold = 70
```

Aplicar cambios:
```bash
terraform apply
```

---

## 🔧 Troubleshooting Rápido

### ❌ No recibo emails
```bash
# Verificar suscripción
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Estado debe ser: "Confirmed"
# Si dice "PendingConfirmation", revisa tu email
```

### ❌ Dashboard vacío
```bash
# Generar tráfico
curl https://$(terraform output -raw eb_environment_cname)

# Esperar 5 minutos y refrescar dashboard
```

### ❌ Alarmas no se activan
```bash
# Probar manualmente
aws cloudwatch set-alarm-state \
  --alarm-name EB-Dynamo-high-5xx-errors \
  --state-value ALARM \
  --state-reason "Test"
```

---

## 📱 Integrar con Slack

### 1. Crear Webhook en Slack
- Ir a: https://api.slack.com/messaging/webhooks
- Crear Incoming Webhook
- Copiar URL del webhook

### 2. Añadir Suscripción
```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol https \
  --notification-endpoint "https://hooks.slack.com/services/TU/WEBHOOK/URL"
```

### 3. Confirmar en Slack
- Recibirás mensaje de confirmación
- Click en el enlace

---

## 📈 Métricas Clave a Monitorear

### Diariamente
- ✅ Errores 5xx (debe ser 0)
- ✅ Latencia P99 (< 1 segundo ideal)
- ✅ Instancias saludables (debe ser 1+)

### Semanalmente
- ✅ Uso promedio de CPU
- ✅ Errores en DynamoDB
- ✅ Tendencias de tráfico

### Mensualmente
- ✅ Costos de CloudWatch
- ✅ Retención de logs
- ✅ Ajuste de umbrales

---

## 💰 Monitorear Costos

### Ver Costos de CloudWatch
```bash
# Mes actual
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://filter-cloudwatch.json

# Crear filter-cloudwatch.json:
echo '{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon CloudWatch"]
  }
}' > filter-cloudwatch.json
```

### Estimación Mensual
```
Dashboard:     $3.00  (1 dashboard)
Alarmas:       $0.00  (primeras 10 gratis)
Logs (1GB):    $0.50  (ingestion)
Logs Storage:  $0.03  (7 días)
SNS:           $0.00  (primeras 1000 gratis)
──────────────────────
TOTAL:         ~$3.53/mes
```

---

## 🎓 Mejores Prácticas

### ✅ DO (Hacer)
- Confirma tu email inmediatamente
- Revisa el dashboard diariamente
- Ajusta umbrales según tu tráfico real
- Documenta respuestas a incidentes
- Prueba las alarmas regularmente

### ❌ DON'T (No Hacer)
- No ignores las alarmas
- No uses umbrales demasiado altos
- No dejes alarmas sin revisar
- No olvides confirmar la suscripción
- No subas `terraform.tfvars` a Git

---

## 📚 Documentación Completa

Para más detalles, consulta:

- **[GUIA_MONITOREO.md](docs/GUIA_MONITOREO.md)** - Guía completa (7000+ palabras)
- **[EJEMPLOS_NOTIFICACIONES.md](docs/EJEMPLOS_NOTIFICACIONES.md)** - Ejemplos de alarmas
- **[RESUMEN_IMPLEMENTACION.md](docs/RESUMEN_IMPLEMENTACION.md)** - Qué se implementó
- **[README_MONITOREO.md](README_MONITOREO.md)** - Documentación general

---

## 🆘 Necesitas Ayuda?

### Comandos Útiles
```bash
# Ver todos los outputs
terraform output

# Ver estado de recursos
terraform show

# Ver logs de terraform
terraform show -json | jq .

# Destruir todo (cuidado!)
terraform destroy
```

### Verificar Salud del Sistema
```bash
# Salud del ambiente
aws elasticbeanstalk describe-environment-health \
  --environment-name eb-dynamo-env \
  --attribute-names All

# Eventos recientes
aws elasticbeanstalk describe-events \
  --environment-name eb-dynamo-env \
  --max-records 10
```

---

## 🎯 Checklist de Implementación

Marca cuando completes cada paso:

- [ ] ✅ Configuré mi email en terraform.tfvars
- [ ] ✅ Ejecuté terraform apply
- [ ] ✅ Confirmé la suscripción por email
- [ ] ✅ Accedí al dashboard de CloudWatch
- [ ] ✅ Probé una alarma con test_alarms.sh
- [ ] ✅ Verifiqué que recibo notificaciones
- [ ] ✅ Revisé la documentación completa
- [ ] ✅ Ajusté umbrales para mi caso de uso
- [ ] ✅ Integré con Slack (opcional)
- [ ] ✅ Documenté procedimientos de respuesta

---

## 🚀 Siguiente Nivel

Una vez que domines lo básico:

1. **Añade métricas personalizadas** desde tu app
2. **Configura auto-scaling** basado en métricas
3. **Implementa AWS X-Ray** para tracing
4. **Crea CloudWatch Synthetics** para monitoreo sintético
5. **Añade anomaly detection** para métricas clave

---

## 💡 Tips Pro

### Tip 1: Alias Útiles
```bash
# Añadir a ~/.bashrc o ~/.zshrc
alias cw-dash='terraform output cloudwatch_dashboard_url | xargs open'
alias cw-logs='aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow'
alias cw-alarms='./test_alarms.sh'
```

### Tip 2: Notificación Desktop (Mac)
```bash
# Cuando llegue una alarma
osascript -e 'display notification "CloudWatch Alarm!" with title "AWS Alert"'
```

### Tip 3: Script de Salud
```bash
# health-check.sh
#!/bin/bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix "EB-Dynamo" \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table
```

---

**🎉 ¡Listo! Ya tienes monitoreo completo de tu aplicación.**

**Recuerda:** El monitoreo es inútil si no actúas sobre las alarmas. 
Revisa el dashboard regularmente y responde a las alertas prontamente.

**¿Problemas?** Consulta [GUIA_MONITOREO.md](docs/GUIA_MONITOREO.md) para troubleshooting detallado.
