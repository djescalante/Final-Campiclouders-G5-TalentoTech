
#!/bin/bash
# ===============================================
# 🚀 Deploy automático EB + DynamoDB - CampiClouders G5
# Autor: José David Escalante
# ===============================================

set -e

# ----- CONFIGURACIÓN BÁSICA -----
REGION="us-east-1"               # Cambia si usas otra región
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_NAME="aws-elasticbeanstalk-ec2-role"
TABLE_NAME="ContactosCampiclouders"
APP_NAME="EB-Dynamo"
ENV_NAME="eb-dynamo-env"
CORS_ORIGIN="*"

echo "==============================================="
echo "🚀 Iniciando despliegue EB + DynamoDB"
echo "==============================================="

# ----- 1. Crear tabla DynamoDB -----
echo "📦 Creando tabla DynamoDB: $TABLE_NAME ..."
aws dynamodb create-table   --region "$REGION"   --table-name "$TABLE_NAME"   --attribute-definitions AttributeName=id,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH   --billing-mode PAY_PER_REQUEST || echo "⚠️ La tabla ya existe."

# ----- 2. Asignar permisos al rol de EB -----
echo "🔐 Asignando permisos al rol $ROLE_NAME ..."
POLICY_JSON=$(cat <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Action":["dynamodb:PutItem","dynamodb:GetItem","dynamodb:Query","dynamodb:Scan","dynamodb:UpdateItem"],
      "Resource":"arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${TABLE_NAME}"
    },
    {
      "Effect":"Allow",
      "Action":["dynamodb:Query"],
      "Resource":"arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${TABLE_NAME}/index/*"
    }
  ]
}
EOF
)
aws iam put-role-policy   --role-name "$ROLE_NAME"   --policy-name "ddbBasicAccess"   --policy-document "$POLICY_JSON"

# ----- 3. Inicializar EB -----
echo "⚙️ Inicializando aplicación Elastic Beanstalk..."
pip install --user awsebcli >/dev/null 2>&1 || true
eb init -p node.js-20 "$APP_NAME" --region "$REGION"

# ----- 4. Crear entorno EB -----
echo "🌐 Creando entorno EB..."
eb create "$ENV_NAME" --single --instance_types t3.micro || echo "⚠️ Entorno ya existe."

# ----- 5. Configurar variables de entorno -----
echo "🧩 Configurando variables de entorno..."
eb setenv TABLE_NAME="$TABLE_NAME" CORS_ORIGIN="$CORS_ORIGIN"

# ----- 6. Despliegue -----
echo "🚀 Desplegando aplicación..."
eb deploy

# ----- 7. Mostrar URL -----
URL=$(eb status | grep "CNAME:" | awk '{print $2}')
echo "==============================================="
echo "✅ Despliegue completado."
echo "🌍 URL pública: https://$URL"
echo "💾 DynamoDB Table: $TABLE_NAME"
echo "📜 Variables: TABLE_NAME=$TABLE_NAME  |  CORS_ORIGIN=$CORS_ORIGIN"
echo "==============================================="
echo "🧠 Recuerda: cambia CORS_ORIGIN por tu dominio real al finalizar las pruebas."
