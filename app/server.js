import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import crypto from "crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json());
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));

// DynamoDB client via EC2 instance role (EB)
const TABLE_NAME = process.env.TABLE_NAME || "ContactosCampiclouders";
const AWS_REGION = process.env.AWS_REGION || "us-east-1";

console.log("=== Configuración ===");
console.log("TABLE_NAME:", TABLE_NAME);
console.log("AWS_REGION:", AWS_REGION);
console.log("CORS_ORIGIN:", process.env.CORS_ORIGIN || "*");

const ddb = DynamoDBDocumentClient.from(
  new DynamoDBClient({ region: AWS_REGION })
);

app.post("/registro", async (req, res) => {
  console.log("POST /registro - Body:", req.body);
  const { nombres, apellido, email, celular, interes } = req.body || {};
  if (!nombres || !apellido || !email || !celular || !interes) {
    console.log("Campos faltantes");
    return res.status(400).json({ error: "Campos requeridos" });
  }
  try {
    const item = {
      id: crypto.randomUUID(),
      nombres, apellido, email, celular, interes,
      createdAt: new Date().toISOString()
    };
    console.log("Guardando item:", item);
    await ddb.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
    console.log("Item guardado exitosamente");
    res.json({ ok: true, id: item.id });
  } catch (e) {
    console.error("Error guardando en DynamoDB:", e);
    console.error("Stack:", e.stack);
    res.status(500).json({ error: "Error interno", details: e.message });
  }
});

// Estático
app.use(express.static(path.join(__dirname, "public")));
app.get("*", (_, res) => res.sendFile(path.join(__dirname, "public", "index.html")));

const port = process.env.PORT || 8080;
app.listen(port, () => console.log("EB + DynamoDB en puerto " + port));
