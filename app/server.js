import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import crypto from "crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json());
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));

// DynamoDB client via EC2 instance role (EB)
const TABLE_NAME = process.env.TABLE_NAME || "ContactosCampiclouders";
const AWS_REGION = process.env.AWS_REGION || "us-east-1";
const MAX_RECORDS = parseInt(process.env.MAX_RECORDS || "100");

console.log("=== Configuración ===");
console.log("TABLE_NAME:", TABLE_NAME);
console.log("AWS_REGION:", AWS_REGION);
console.log("CORS_ORIGIN:", process.env.CORS_ORIGIN || "*");
console.log("MAX_RECORDS:", MAX_RECORDS);

const ddb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: AWS_REGION })
);

// Cache para el contador de registros (evita Scans frecuentes)
let cachedCount = 0;
let lastCheck = 0;
const CACHE_TTL = 60000; // 1 minuto

/**
 * Obtiene el número actual de registros en la tabla
 * Usa cache para evitar Scans innecesarios
 */
async function getRecordCount() {
  const now = Date.now();
  
  // Si el cache es reciente, usarlo
  if (now - lastCheck < CACHE_TTL) {
    console.log("Usando contador en cache:", cachedCount);
    return cachedCount;
  }
  
  // Si no, hacer Scan
  try {
    console.log("Actualizando contador desde DynamoDB...");
    const result = await ddb.send(new ScanCommand({
      TableName: TABLE_NAME,
      Select: "COUNT"  // Solo contar, no devolver datos
    }));
    
    cachedCount = result.Count || 0;
    lastCheck = now;
    console.log("Contador actualizado:", cachedCount);
    
    return cachedCount;
  } catch (error) {
    console.error("Error obteniendo contador:", error);
    // En caso de error, devolver el cache (aunque esté vencido)
    return cachedCount;
  }
}

/**
 * Endpoint principal: Registrar un nuevo contacto
 * Valida el límite de registros antes de insertar
 */
app.post("/registro", async (req, res) => {
  console.log("POST /registro - Body:", req.body);
  const { nombres, apellido, email, celular, interes } = req.body || {};
  
  // Validar campos requeridos
  if (!nombres || !apellido || !email || !celular || !interes) {
    console.log("Campos faltantes");
    return res.status(400).json({ 
      error: "Campos requeridos",
      message: "Todos los campos son obligatorios: nombres, apellido, email, celular, interes"
    });
  }
  
  try {
    // 1. Verificar límite de registros
    const currentCount = await getRecordCount();
    console.log(`Registros actuales: ${currentCount}/${MAX_RECORDS}`);
    
    if (currentCount >= MAX_RECORDS) {
      console.log("⚠️ Límite de registros alcanzado");
      return res.status(429).json({ 
        error: "Límite alcanzado",
        message: `La base de datos ha alcanzado su capacidad máxima de ${MAX_RECORDS} registros`,
        currentCount: currentCount,
        maxRecords: MAX_RECORDS
      });
    }
    
    // 2. Crear el registro
    const item = {
      id: crypto.randomUUID(),
      nombres,
      apellido,
      email,
      celular,
      interes,
      createdAt: new Date().toISOString()
    };
    
    console.log("Guardando item:", item);
    
    // 3. Guardar en DynamoDB
    await ddb.send(new PutCommand({ 
      TableName: TABLE_NAME, 
      Item: item 
    }));
    
    // 4. Actualizar cache
    cachedCount++;
    
    console.log("✅ Item guardado exitosamente");
    
    // 5. Responder con éxito
    res.json({ 
      ok: true, 
      id: item.id,
      message: "Registro creado exitosamente",
      stats: {
        currentCount: cachedCount,
        maxRecords: MAX_RECORDS,
        remainingSlots: MAX_RECORDS - cachedCount,
        percentUsed: ((cachedCount / MAX_RECORDS) * 100).toFixed(1)
      }
    });
    
  } catch (e) {
    console.error("❌ Error guardando en DynamoDB:", e);
    console.error("Stack:", e.stack);
    res.status(500).json({ 
      error: "Error interno", 
      message: "Ocurrió un error al guardar el registro",
      details: process.env.NODE_ENV === 'development' ? e.message : undefined
    });
  }
});

/**
 * Endpoint: Obtener estadísticas de la base de datos
 * Muestra uso actual, capacidad, y porcentaje utilizado
 */
app.get("/stats", async (req, res) => {
  try {
    // Forzar actualización del contador (sin cache)
    lastCheck = 0;
    const currentCount = await getRecordCount();
    
    const stats = {
      currentCount: currentCount,
      maxRecords: MAX_RECORDS,
      remainingSlots: MAX_RECORDS - currentCount,
      percentUsed: ((currentCount / MAX_RECORDS) * 100).toFixed(1),
      isNearLimit: currentCount >= (MAX_RECORDS * 0.8), // 80% del límite
      isFull: currentCount >= MAX_RECORDS
    };
    
    console.log("Stats solicitadas:", stats);
    res.json(stats);
    
  } catch (e) {
    console.error("Error obteniendo stats:", e);
    res.status(500).json({ 
      error: "Error interno",
      message: "No se pudieron obtener las estadísticas"
    });
  }
});

/**
 * Endpoint: Health check
 * Verifica que el servicio esté funcionando
 */
app.get("/health", (req, res) => {
  res.json({ 
    status: "ok",
    service: "EB-Dynamo",
    timestamp: new Date().toISOString(),
    config: {
      tableName: TABLE_NAME,
      region: AWS_REGION,
      maxRecords: MAX_RECORDS
    }
  });
});

// Servir archivos estáticos
app.use(express.static(path.join(__dirname, "public")));

// Ruta catch-all para SPA
app.get("*", (_, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// Iniciar servidor
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log("=".repeat(50));
  console.log(`🚀 Servidor corriendo en puerto ${port}`);
  console.log(`📊 Límite de registros: ${MAX_RECORDS}`);
  console.log(`🌍 Región: ${AWS_REGION}`);
  console.log(`📚 Tabla: ${TABLE_NAME}`);
  console.log("=".repeat(50));
});
