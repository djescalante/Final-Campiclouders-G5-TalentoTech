# 🔢 Limitar Cantidad de Registros en DynamoDB

## 🎯 Opciones Disponibles

Tienes varias formas de limitar los registros en DynamoDB. Aquí te muestro todas las opciones con sus pros y contras:

---

## Opción 1: Lógica en la Aplicación (✅ Recomendado)

### Descripción
Validar el número de registros antes de insertar en tu código Node.js.

### Ventajas
- ✅ Control total sobre la lógica
- ✅ Puedes personalizar el mensaje de error
- ✅ Fácil de implementar y mantener
- ✅ No requiere cambios en infraestructura

### Desventajas
- ❌ Requiere un Scan (puede ser costoso con muchos datos)
- ❌ No previene inserciones desde otras fuentes (API, consola)

### Implementación

```javascript
// server.js
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

const MAX_RECORDS = 100; // Límite de registros

app.post("/registro", async (req, res) => {
  console.log("POST /registro - Body:", req.body);
  const { nombres, apellido, email, celular, interes } = req.body || {};
  
  if (!nombres || !apellido || !email || !celular || !interes) {
    console.log("Campos faltantes");
    return res.status(400).json({ error: "Campos requeridos" });
  }
  
  try {
    // 1. Contar registros actuales
    const countResult = await ddb.send(new ScanCommand({
      TableName: TABLE_NAME,
      Select: "COUNT"
    }));
    
    const currentCount = countResult.Count || 0;
    console.log(`Registros actuales: ${currentCount}/${MAX_RECORDS}`);
    
    // 2. Verificar límite
    if (currentCount >= MAX_RECORDS) {
      console.log("Límite de registros alcanzado");
      return res.status(429).json({ 
        error: "Límite alcanzado",
        message: `La base de datos ha alcanzado el límite de ${MAX_RECORDS} registros`,
        currentCount: currentCount
      });
    }
    
    // 3. Guardar registro
    const item = {
      id: crypto.randomUUID(),
      nombres, apellido, email, celular, interes,
      createdAt: new Date().toISOString()
    };
    
    console.log("Guardando item:", item);
    await ddb.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
    
    console.log("Item guardado exitosamente");
    res.json({ 
      ok: true, 
      id: item.id,
      remainingSlots: MAX_RECORDS - currentCount - 1
    });
    
  } catch (e) {
    console.error("Error guardando en DynamoDB:", e);
    res.status(500).json({ error: "Error interno", details: e.message });
  }
});

// Nuevo endpoint: Obtener estadísticas
app.get("/stats", async (req, res) => {
  try {
    const countResult = await ddb.send(new ScanCommand({
      TableName: TABLE_NAME,
      Select: "COUNT"
    }));
    
    const currentCount = countResult.Count || 0;
    
    res.json({
      currentCount: currentCount,
      maxRecords: MAX_RECORDS,
      remainingSlots: MAX_RECORDS - currentCount,
      percentUsed: ((currentCount / MAX_RECORDS) * 100).toFixed(2)
    });
  } catch (e) {
    console.error("Error obteniendo stats:", e);
    res.status(500).json({ error: "Error interno" });
  }
});
```

---

## Opción 2: TTL (Time To Live) - Auto-eliminación

### Descripción
Configurar DynamoDB para que elimine automáticamente registros antiguos.

### Ventajas
- ✅ Automático - No requiere código
- ✅ Sin costo adicional
- ✅ Mantiene solo registros recientes
- ✅ Ideal para datos temporales

### Desventajas
- ❌ La eliminación puede tardar hasta 48 horas
- ❌ No es un límite exacto de cantidad
- ❌ Requiere añadir campo TTL a cada registro

### Implementación en Terraform

```hcl
# En main.tf, actualizar el recurso DynamoDB

resource "aws_dynamodb_table" "contacts" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Configurar TTL
  ttl {
    enabled        = true
    attribute_name = "expiresAt"
  }
}
```

### Actualizar código de la aplicación

```javascript
// server.js - Añadir campo expiresAt
const DAYS_TO_EXPIRE = 30; // Registros expiran en 30 días

app.post("/registro", async (req, res) => {
  // ... validaciones ...
  
  try {
    const now = Math.floor(Date.now() / 1000); // Unix timestamp
    const expiresAt = now + (DAYS_TO_EXPIRE * 24 * 60 * 60);
    
    const item = {
      id: crypto.randomUUID(),
      nombres, apellido, email, celular, interes,
      createdAt: new Date().toISOString(),
      expiresAt: expiresAt  // ← Campo TTL
    };
    
    await ddb.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
    res.json({ ok: true, id: item.id });
  } catch (e) {
    console.error("Error:", e);
    res.status(500).json({ error: "Error interno" });
  }
});
```

---

## Opción 3: Lambda + DynamoDB Streams

### Descripción
Usar una función Lambda que se activa cuando se alcanza el límite y elimina el registro más antiguo.

### Ventajas
- ✅ Límite exacto de registros
- ✅ FIFO (First In, First Out) automático
- ✅ No afecta rendimiento de la aplicación
- ✅ Funciona aunque insertes desde consola

### Desventajas
- ❌ Más complejo de implementar
- ❌ Costo adicional de Lambda
- ❌ Requiere habilitar Streams en DynamoDB

### Implementación en Terraform

```hcl
# monitoring.tf o nuevo archivo: dynamodb-limits.tf

# Variable para el límite
variable "max_records" {
  description = "Máximo número de registros en DynamoDB"
  type        = number
  default     = 100
}

# Habilitar Streams en DynamoDB
resource "aws_dynamodb_table" "contacts" {
  # ... configuración existente ...
  
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

# IAM Role para Lambda
resource "aws_iam_role" "limit_enforcer_lambda" {
  name = "${var.app_name}-limit-enforcer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Políticas para Lambda
resource "aws_iam_role_policy" "limit_enforcer_policy" {
  name = "${var.app_name}-limit-enforcer-policy"
  role = aws_iam_role.limit_enforcer_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.contacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ]
        Resource = "${aws_dynamodb_table.contacts.arn}/stream/*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "limit_enforcer" {
  filename      = "lambda/limit-enforcer.zip"
  function_name = "${var.app_name}-limit-enforcer"
  role          = aws_iam_role.limit_enforcer_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60

  environment {
    variables = {
      TABLE_NAME  = var.table_name
      MAX_RECORDS = var.max_records
    }
  }
}

# Event Source Mapping
resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  event_source_arn  = aws_dynamodb_table.contacts.stream_arn
  function_name     = aws_lambda_function.limit_enforcer.arn
  starting_position = "LATEST"
}
```

### Código Lambda (lambda/index.js)

```javascript
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME;
const MAX_RECORDS = parseInt(process.env.MAX_RECORDS || "100");

export const handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));
  
  try {
    // 1. Contar registros
    const scanResult = await ddb.send(new ScanCommand({
      TableName: TABLE_NAME,
      ProjectionExpression: "id, createdAt"
    }));
    
    const items = scanResult.Items || [];
    const currentCount = items.length;
    
    console.log(`Registros actuales: ${currentCount}/${MAX_RECORDS}`);
    
    // 2. Si excede el límite, eliminar los más antiguos
    if (currentCount > MAX_RECORDS) {
      const excess = currentCount - MAX_RECORDS;
      console.log(`Exceso de ${excess} registros. Eliminando los más antiguos...`);
      
      // Ordenar por fecha de creación (más antiguo primero)
      const sorted = items.sort((a, b) => 
        new Date(a.createdAt) - new Date(b.createdAt)
      );
      
      // Eliminar los excedentes
      for (let i = 0; i < excess; i++) {
        const itemToDelete = sorted[i];
        console.log(`Eliminando: ${itemToDelete.id}`);
        
        await ddb.send(new DeleteCommand({
          TableName: TABLE_NAME,
          Key: { id: itemToDelete.id }
        }));
      }
      
      console.log(`Eliminados ${excess} registros exitosamente`);
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Límite verificado",
        currentCount: currentCount,
        maxRecords: MAX_RECORDS
      })
    };
    
  } catch (error) {
    console.error("Error:", error);
    throw error;
  }
};
```

---

## Opción 4: CloudWatch Alarm + Lambda (Monitoreo Proactivo)

### Descripción
Crear una alarma que se active cuando estés cerca del límite y notifique o ejecute acciones.

### Ventajas
- ✅ Notificación proactiva
- ✅ Puedes tomar acción antes de alcanzar el límite
- ✅ Integrado con sistema de monitoreo existente

### Implementación

```hcl
# En monitoring.tf

# Métrica personalizada para contar registros
resource "aws_cloudwatch_log_metric_filter" "record_count" {
  name           = "${var.app_name}-record-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[time, request, method=POST, path=/registro, ...]"

  metric_transformation {
    name      = "RecordInsertions"
    namespace = "${var.app_name}/Database"
    value     = "1"
  }
}

# Alarma cuando te acercas al límite
resource "aws_cloudwatch_metric_alarm" "approaching_limit" {
  alarm_name          = "${var.app_name}-approaching-record-limit"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RecordInsertions"
  namespace           = "${var.app_name}/Database"
  period              = "86400" # 24 horas
  statistic           = "Sum"
  threshold           = "80" # Alerta al 80% del límite
  alarm_description   = "Se está acercando al límite de registros"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

---

## Opción 5: API Gateway Quota (Limitar Peticiones)

### Descripción
Si tu aplicación usa API Gateway, puedes limitar el número de peticiones.

### Implementación

```hcl
# Si usas API Gateway (alternativa a Elastic Beanstalk)
resource "aws_api_gateway_usage_plan" "quota" {
  name = "${var.app_name}-quota"

  quota_settings {
    limit  = 100  # 100 peticiones
    period = "DAY"
  }
}
```

---

## 📊 Comparación de Opciones

| Opción | Complejidad | Costo | Precisión | Recomendado Para |
|--------|-------------|-------|-----------|------------------|
| **Lógica en App** | Baja | Bajo | Alta | Proyectos simples, demos |
| **TTL** | Baja | Gratis | Baja | Datos temporales |
| **Lambda + Streams** | Alta | Medio | Muy Alta | Producción con límite exacto |
| **CloudWatch Alarm** | Media | Bajo | Media | Monitoreo y alertas |
| **API Gateway** | Media | Medio | Alta | APIs públicas |

---

## 🎯 Recomendación por Caso de Uso

### Para un Bootcamp/Demo (Tu Caso)
```
✅ Opción 1: Lógica en la Aplicación
- Fácil de implementar
- Control total
- Suficiente para demo
```

### Para Producción Pequeña
```
✅ Opción 1 + Opción 2 (TTL)
- Límite en aplicación
- Limpieza automática de datos antiguos
```

### Para Producción Empresarial
```
✅ Opción 3: Lambda + Streams
- Límite exacto y automático
- Funciona siempre
- Escalable
```

---

## 🚀 Implementación Rápida (Opción 1)

Te voy a crear el código actualizado para tu aplicación con límite de 100 registros:

### Actualización sugerida para server.js:

1. Añadir variable de entorno `MAX_RECORDS`
2. Verificar cantidad antes de insertar
3. Añadir endpoint `/stats` para ver uso

¿Quieres que actualice tu `server.js` con la Opción 1 (lógica en aplicación)?

---

## 💡 Tips Adicionales

### Optimizar el Scan
```javascript
// En lugar de Scan completo, usar Count
const countResult = await ddb.send(new ScanCommand({
  TableName: TABLE_NAME,
  Select: "COUNT"  // Solo cuenta, no devuelve datos
}));
```

### Cache del Contador
```javascript
// Cachear el contador para no hacer Scan en cada petición
let cachedCount = 0;
let lastCheck = 0;
const CACHE_TTL = 60000; // 1 minuto

async function getRecordCount() {
  const now = Date.now();
  if (now - lastCheck > CACHE_TTL) {
    const result = await ddb.send(new ScanCommand({
      TableName: TABLE_NAME,
      Select: "COUNT"
    }));
    cachedCount = result.Count || 0;
    lastCheck = now;
  }
  return cachedCount;
}
```

---

¿Qué opción prefieres implementar? Puedo ayudarte a actualizar tu código con la solución que elijas.
