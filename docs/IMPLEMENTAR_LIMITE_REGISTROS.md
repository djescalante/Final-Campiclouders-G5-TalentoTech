# 🚀 Implementación Rápida - Límite de Registros

## ✅ ¿Qué se ha agregado?

Se ha implementado un **límite de registros en DynamoDB** con las siguientes características:

- ✅ Límite configurable (default: 100 registros)
- ✅ Validación antes de insertar
- ✅ Cache inteligente para evitar Scans frecuentes
- ✅ Endpoint `/stats` para monitorear uso
- ✅ Endpoint `/health` para health checks
- ✅ Respuestas detalladas con información de capacidad

---

## 📁 Archivos Actualizados

### 1. **app/server-with-limit.js** (NUEVO)
Versión actualizada del servidor con límite de registros.

### 2. **main.tf**
✅ Agregada variable de entorno `MAX_RECORDS`

### 3. **variables.tf**
✅ Nueva variable `max_records` (default: 100)

### 4. **terraform.tfvars**
✅ Configuración de `max_records = 100`

### 5. **terraform.tfvars.example**
✅ Ejemplo documentado

### 6. **docs/LIMITAR_REGISTROS_DYNAMODB.md**
✅ Guía completa con todas las opciones

---

## 🎯 Opción Implementada: Lógica en Aplicación

### Características:
- ✅ **Límite configurable**: Cambia el valor en `terraform.tfvars`
- ✅ **Cache inteligente**: Evita Scans frecuentes (TTL: 1 minuto)
- ✅ **Respuestas HTTP apropiadas**: 
  - `200` cuando se guarda correctamente
  - `429` cuando se alcanza el límite
  - `400` para errores de validación
  - `500` para errores del servidor

### Endpoints Nuevos:

#### 1. POST /registro (Actualizado)
```javascript
// Respuesta exitosa
{
  "ok": true,
  "id": "uuid-del-registro",
  "message": "Registro creado exitosamente",
  "stats": {
    "currentCount": 45,
    "maxRecords": 100,
    "remainingSlots": 55,
    "percentUsed": "45.0"
  }
}

// Cuando se alcanza el límite
{
  "error": "Límite alcanzado",
  "message": "La base de datos ha alcanzado su capacidad máxima de 100 registros",
  "currentCount": 100,
  "maxRecords": 100
}
```

#### 2. GET /stats (Nuevo)
```javascript
{
  "currentCount": 75,
  "maxRecords": 100,
  "remainingSlots": 25,
  "percentUsed": "75.0",
  "isNearLimit": false,  // true cuando >= 80%
  "isFull": false        // true cuando >= 100%
}
```

#### 3. GET /health (Nuevo)
```javascript
{
  "status": "ok",
  "service": "EB-Dynamo",
  "timestamp": "2024-11-05T10:00:00.000Z",
  "config": {
    "tableName": "ContactosCampiclouders",
    "region": "us-east-1",
    "maxRecords": 100
  }
}
```

---

## 🚀 Cómo Implementar

### Opción A: Reemplazar server.js (Recomendado)

```bash
# 1. Backup del archivo actual
cp app/server.js app/server.js.backup

# 2. Reemplazar con la nueva versión
cp app/server-with-limit.js app/server.js

# 3. Configurar límite en terraform.tfvars
code terraform.tfvars
# Cambiar: max_records = 100  # (o el valor que prefieras)

# 4. Aplicar cambios
terraform apply
```

### Opción B: Usar server-with-limit.js directamente

```bash
# 1. Actualizar Procfile
echo "web: node server-with-limit.js" > app/Procfile

# 2. Configurar límite en terraform.tfvars
code terraform.tfvars
# max_records = 100

# 3. Aplicar cambios
terraform apply
```

---

## ⚙️ Configuración

### Cambiar el Límite de Registros

En `terraform.tfvars`:

```hcl
# Para demo/desarrollo
max_records = 50

# Para producción pequeña
max_records = 500

# Para producción grande
max_records = 10000
```

Luego aplicar:
```bash
terraform apply
```

---

## 🧪 Probar la Implementación

### 1. Verificar Health Check
```bash
curl https://$(terraform output -raw eb_environment_cname)/health
```

### 2. Ver Estadísticas
```bash
curl https://$(terraform output -raw eb_environment_cname)/stats
```

### 3. Crear Registro
```bash
curl -X POST https://$(terraform output -raw eb_environment_cname)/registro \
  -H "Content-Type: application/json" \
  -d '{
    "nombres": "Juan",
    "apellido": "Pérez",
    "email": "juan@ejemplo.com",
    "celular": "1234567890",
    "interes": "Bootcamp"
  }'
```

### 4. Probar Límite
```bash
# Script para llenar la base de datos
for i in {1..105}; do
  curl -X POST https://$(terraform output -raw eb_environment_cname)/registro \
    -H "Content-Type: application/json" \
    -d "{
      \"nombres\": \"Usuario$i\",
      \"apellido\": \"Test\",
      \"email\": \"user$i@test.com\",
      \"celular\": \"123456789$i\",
      \"interes\": \"Testing\"
    }"
  echo ""
done
```

---

## 📊 Monitoreo

### Logs en CloudWatch
```bash
# Ver logs en tiempo real
aws logs tail /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env --follow

# Filtrar mensajes de límite
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/EB-Dynamo/eb-dynamo-env \
  --filter-pattern "Límite alcanzado"
```

### Alarma de CloudWatch (Opcional)

Puedes agregar una alarma en `monitoring.tf`:

```hcl
resource "aws_cloudwatch_metric_alarm" "near_capacity" {
  alarm_name          = "${var.app_name}-near-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RecordCount"
  namespace           = "${var.app_name}/Database"
  period              = "300"
  statistic           = "Average"
  threshold           = var.max_records * 0.8  # 80% del límite
  alarm_description   = "Base de datos cerca de su capacidad máxima"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

---

## 🔧 Troubleshooting

### El contador no es preciso

**Problema**: El cache hace que el contador no sea 100% preciso.

**Solución**: Esto es normal y esperado. El cache se actualiza cada minuto para evitar Scans costosos. Si necesitas el valor exacto:

```bash
# Llamar a /stats (que fuerza actualización)
curl https://tu-app.com/stats
```

### Error: Scan is too expensive

**Problema**: Muchos registros hacen que el Scan sea lento.

**Soluciones**:
1. Aumentar el TTL del cache (de 60s a 300s)
2. Implementar Lambda + Streams (ver docs/LIMITAR_REGISTROS_DYNAMODB.md)
3. Usar un contador en un ítem separado de DynamoDB

### Los registros siguen insertándose después del límite

**Problema**: Condición de carrera en alta concurrencia.

**Solución**: Si tienes mucho tráfico simultáneo, considera:
1. Usar DynamoDB Transactions
2. Implementar Lambda + Streams
3. Usar API Gateway con throttling

---

## 💡 Mejores Prácticas

### 1. Ajusta el Límite Según Tu Caso

```hcl
# Demo/Bootcamp
max_records = 50-100

# Desarrollo
max_records = 500

# Producción
max_records = 10000+
```

### 2. Monitorea el Uso

Crea un dashboard personalizado:

```hcl
# En monitoring.tf, agregar widget para uso de capacidad
{
  type = "metric"
  properties = {
    metrics = [
      ["${var.app_name}/Database", "RecordCount"]
    ]
    view = "singleValue"
    title = "Registros Usados"
  }
}
```

### 3. Implementa Limpieza Automática (Opcional)

Si quieres que los registros antiguos se eliminen:

```hcl
# En main.tf
resource "aws_dynamodb_table" "contacts" {
  # ... configuración existente ...
  
  ttl {
    enabled        = true
    attribute_name = "expiresAt"
  }
}
```

Luego en el código:
```javascript
const DAYS_TO_EXPIRE = 30;
const expiresAt = Math.floor(Date.now() / 1000) + (DAYS_TO_EXPIRE * 24 * 60 * 60);

const item = {
  // ... campos existentes ...
  expiresAt: expiresAt
};
```

---

## 📚 Recursos Adicionales

- **docs/LIMITAR_REGISTROS_DYNAMODB.md** - Guía completa con todas las opciones
- **app/server-with-limit.js** - Código con comentarios detallados
- **DynamoDB Best Practices**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html

---

## 🎯 Resumen

✅ **Implementado**: Límite de registros con lógica en aplicación  
✅ **Configurable**: Variable `max_records` en Terraform  
✅ **Eficiente**: Cache para evitar Scans frecuentes  
✅ **Monitoreado**: Endpoints `/stats` y `/health`  
✅ **Documentado**: Guía completa y ejemplos  

**Próximo paso**: Reemplaza `server.js` con `server-with-limit.js` y ejecuta `terraform apply`.

---

## 📞 ¿Preguntas?

- Ver todas las opciones: `docs/LIMITAR_REGISTROS_DYNAMODB.md`
- Revisar código: `app/server-with-limit.js`
- Consultar monitoreo: `docs/GUIA_MONITOREO.md`
