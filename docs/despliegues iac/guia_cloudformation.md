# ☁️ Guía de Despliegue con CloudFormation — EB + DynamoDB

Usa esta guía para desplegar la infraestructura y la aplicación desde la consola web de AWS, apoyándote en una plantilla CloudFormation incluida en `cloudformation/eb-dynamo.yml`.

---

## ✅ Prerrequisitos
- Cuenta AWS con permisos sobre: CloudFormation, Elastic Beanstalk, S3, IAM, DynamoDB.
- Paquete de la aplicación en formato ZIP (debe contener `package.json`, `server.js` y carpeta `public/`).

Para crear el zip rápidamente:
- Windows PowerShell: `Compress-Archive -Path server.js,package.json,public/* -DestinationPath app.zip -Force`
- Linux/macOS: `zip -r app.zip server.js package.json public`

---

## 1) Subir el paquete a S3
1. Entra a S3 → Crea (o usa) un bucket para artefactos (ej. `my-eb-artifacts-<account>-<region>`).
2. Sube `app.zip` (recomendado en la ruta `app/<version>.zip`).
3. Copia el Bucket y el Key (ruta) del objeto subido.

---

## 2) Crear el stack de CloudFormation
1. Abre CloudFormation → Create stack → With new resources (standard).
2. Selecciona “Upload a template file” y sube `cloudformation/eb-dynamo.yml`.
3. En “Specify stack details”, completa los parámetros:
   - `AppName`: `EB-Dynamo`
   - `EnvName`: `eb-dynamo-env`
   - `TableName`: `ContactosCampiclouders`
   - `CorsOrigin`: `*` (o tu dominio)
   - `InstanceType`: `t3.micro`
   - `PlatformArn`: Platform ARN válido para Node.js 20 (AL2023) en tu región. Ejemplo: `arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 20 running on 64bit Amazon Linux 2023/5.10.1`
   - `SourceS3Bucket`: el bucket donde subiste `app.zip`
   - `SourceS3Key`: la clave/ruta del `app.zip` (ej. `app/v-2025-10-30.zip`)
4. Next → Next → Marca las casillas de capacidades IAM si las pide → Create stack.

La plantilla creará:
- DynamoDB Table.
- EB Application + ApplicationVersion (apuntando al ZIP en S3).
- IAM roles: service role de EB y rol de instancia EC2 con permisos mínimos a DynamoDB.
- EB Environment (SingleInstance) con variables `TABLE_NAME`, `CORS_ORIGIN`, `NODE_ENV=production` y `AWS_REGION`.

---

## 3) Verificar y probar
1. En la vista del stack, pestaña “Outputs”, copia `EBEnvironmentURL` y ábrela.
2. Envía el formulario; debe responder con `ok: true` y un `id`.
3. En DynamoDB, revisa la tabla `TableName` y confirma el ítem creado.

---

## 4) Actualizar la aplicación (nueva versión)
1. Empaqueta una nueva `app.zip` con tus cambios.
2. Sube a S3 con un nuevo Key (p. ej., `app/v-2025-11-01.zip`).
3. En CloudFormation → Select stack → Update → Use current template.
4. Cambia el parámetro `SourceS3Key` al nuevo Key.
5. Siguiente → Actualiza el stack. El environment adoptará la nueva versión.

---

## 🧹 Limpieza
Para eliminar todo:
1. Elimina el stack en CloudFormation (borra EB env/app, roles e incluso la tabla DynamoDB).
2. Borra el objeto ZIP y si quieres el bucket S3 (si fue creado por ti aparte).

---

## ❗ Solución de problemas
- Platform ARN inválido: asegúrate de usar uno válido de tu región. Puedes listarlos con AWS CLI `aws elasticbeanstalk list-platform-versions`.
- Conflicto de nombres IAM: si ya existen roles con los mismos nombres, cambia `AppName` para generar nombres distintos.
- EB queda en “Severe”: revisa Logs en EB y confirma `TABLE_NAME`/`CORS_ORIGIN` y permisos del Instance Profile.

---

## 🔗 Limpieza avanzada
Consulta `guia_limpieza.md` para pasos detallados de desmontaje en todos los métodos (Terraform, CLI, CloudFormation y consola web).
