# 🚀 Guía de Despliegue con AWS CLI — EB + DynamoDB

Esta guía usa exclusivamente la AWS CLI para crear DynamoDB, los roles necesarios, empaquetar/subir la app a S3 y crear la Application/Environment de Elastic Beanstalk.

---

## ✅ Prerrequisitos
- AWS CLI v2 configurada (`aws configure`).
- S3 habilitado en tu cuenta/region para almacenar el paquete de la app.
- Node.js 20+ para construir localmente si lo necesitas.

---

## 🔧 Variables (ajusta a tu entorno)

Linux/macOS (bash):
```bash
export AWS_REGION=us-east-1
export APP_NAME=EB-Dynamo
export ENV_NAME=eb-dynamo-env
export TABLE_NAME=ContactosCampiclouders
export CORS_ORIGIN="*"
export INSTANCE_TYPE=t3.micro
export BUCKET_NAME=my-eb-artifacts-$(aws sts get-caller-identity --query Account --output text)-$AWS_REGION
export PLATFORM_ARN="arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 20 running on 64bit Amazon Linux 2023/5.10.1"
export VERSION_LABEL="v-$(date +%Y%m%d-%H%M%S)"
```

Windows PowerShell:
```powershell
$env:AWS_REGION = "us-east-1"
$env:APP_NAME = "EB-Dynamo"
$env:ENV_NAME = "eb-dynamo-env"
$env:TABLE_NAME = "ContactosCampiclouders"
$env:CORS_ORIGIN = "*"
$env:INSTANCE_TYPE = "t3.micro"
$AccountId = (aws sts get-caller-identity --query Account --output text)
$env:BUCKET_NAME = "my-eb-artifacts-$AccountId-$($env:AWS_REGION)"
$env:PLATFORM_ARN = "arn:aws:elasticbeanstalk:us-east-1::platform/Node.js 20 running on 64bit Amazon Linux 2023/5.10.1"
$env:VERSION_LABEL = "v-" + (Get-Date -Format "yyyyMMdd-HHmmss")
```

---

## 1) Crear recursos base

1. Bucket S3 para artefactos EB
```bash
# Nota: en us-east-1 no uses --create-bucket-configuration
if [ "$AWS_REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" 2>/dev/null || true
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || true
fi
```

2. Tabla DynamoDB (si no existe)
```bash
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST 2>/dev/null || true
```

3. Rol de instancia EC2 para EB + Instance Profile
```bash
cat > trust-ec2.json <<'JSON'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}
JSON

ROLE_NAME="${APP_NAME}-eb-ec2-role"
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-ec2.json 2>/dev/null || true

# Política mínima para la tabla DynamoDB
TABLE_ARN="arn:aws:dynamodb:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):table/${TABLE_NAME}"
cat > ddb-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect":"Allow","Action":["dynamodb:PutItem","dynamodb:GetItem","dynamodb:Query","dynamodb:Scan","dynamodb:UpdateItem"],"Resource":"${TABLE_ARN}"},
    {"Effect":"Allow","Action":["dynamodb:Query"],"Resource":"${TABLE_ARN}/index/*"}
  ]
}
JSON
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name ddbBasicAccess --policy-document file://ddb-policy.json

aws iam create-instance-profile --instance-profile-name "${ROLE_NAME}-profile" 2>/dev/null || true
aws iam add-role-to-instance-profile --role-name "$ROLE_NAME" --instance-profile-name "${ROLE_NAME}-profile" 2>/dev/null || true
```

4. Service Role para EB (mejores métricas y permisos internos)
```bash
cat > trust-eb.json <<'JSON'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"elasticbeanstalk.amazonaws.com"},"Action":"sts:AssumeRole"}]}
JSON

SR_NAME="${APP_NAME}-eb-service-role"
aws iam create-role --role-name "$SR_NAME" --assume-role-policy-document file://trust-eb.json 2>/dev/null || true
aws iam attach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth
aws iam attach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkService
```

---

## 2) Empaquetar y subir la aplicación

Windows PowerShell (desde la raíz del proyecto):
```powershell
Compress-Archive -Path server.js,package.json,public/* -DestinationPath app.zip -Force
aws s3 cp .\app.zip s3://$env:BUCKET_NAME/app/$env:VERSION_LABEL.zip
```

Linux/macOS:
```bash
zip -r app.zip server.js package.json public
aws s3 cp ./app.zip s3://$BUCKET_NAME/app/$VERSION_LABEL.zip
```

---

## 3) Crear Application, Version y Environment en EB

1. Application
```bash
aws elasticbeanstalk create-application --application-name "$APP_NAME" 2>/dev/null || true
```

2. Application Version (apunta a S3)
```bash
aws elasticbeanstalk create-application-version \
  --application-name "$APP_NAME" \
  --version-label "$VERSION_LABEL" \
  --source-bundle S3Bucket="$BUCKET_NAME",S3Key="app/$VERSION_LABEL.zip"
```

3. Environment (usar Platform ARN AL2023 Node.js 20)
```bash
aws elasticbeanstalk create-environment \
  --application-name "$APP_NAME" \
  --environment-name "$ENV_NAME" \
  --platform-arn "$PLATFORM_ARN" \
  --version-label "$VERSION_LABEL" \
  --option-settings \
    Namespace="aws:elasticbeanstalk:environment",OptionName="EnvironmentType",Value="SingleInstance" \
    Namespace="aws:autoscaling:launchconfiguration",OptionName="InstanceType",Value="$INSTANCE_TYPE" \
    Namespace="aws:autoscaling:launchconfiguration",OptionName="IamInstanceProfile",Value="${APP_NAME}-eb-ec2-role-profile" \
    Namespace="aws:elasticbeanstalk:application:environment",OptionName="TABLE_NAME",Value="$TABLE_NAME" \
    Namespace="aws:elasticbeanstalk:application:environment",OptionName="CORS_ORIGIN",Value="$CORS_ORIGIN" \
    Namespace="aws:elasticbeanstalk:application:environment",OptionName="AWS_REGION",Value="$AWS_REGION" \
    Namespace="aws:elasticbeanstalk:application:environment",OptionName="NODE_ENV",Value="production" \
    Namespace="aws:elasticbeanstalk:environment",OptionName="ServiceRole",Value="${APP_NAME}-eb-service-role"
```

4. Espera la salud del environment
```bash
aws elasticbeanstalk describe-environments --application-name "$APP_NAME" --environment-names "$ENV_NAME" --query "Environments[0].Status"
```

---

## 4) Prueba
- Obtén el CNAME/URL:
```bash
aws elasticbeanstalk describe-environments --application-name "$APP_NAME" --environment-names "$ENV_NAME" --query "Environments[0].[CNAME,Health,Status]"
```
- Abre la URL y envía el formulario (POST `/registro`).
- Verifica el ítem en DynamoDB.

---

## 🧹 Limpieza
```bash
aws elasticbeanstalk terminate-environment --environment-name "$ENV_NAME"
aws elasticbeanstalk delete-application --application-name "$APP_NAME" --terminate-env-by-force
aws dynamodb delete-table --table-name "$TABLE_NAME"
aws iam detach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth || true
aws iam detach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkService || true
aws iam delete-role --role-name "$SR_NAME" || true
aws iam remove-role-from-instance-profile --role-name "$ROLE_NAME" --instance-profile-name "${ROLE_NAME}-profile" || true
aws iam delete-instance-profile --instance-profile-name "${ROLE_NAME}-profile" || true
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name ddbBasicAccess || true
aws iam delete-role --role-name "$ROLE_NAME" || true
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-bucket --bucket "$BUCKET_NAME" || true

# Limpieza de archivos locales
rm -f trust-ec2.json ddb-policy.json trust-eb.json app.zip
```

---

## 🔗 Limpieza avanzada
Para ver todas las variantes de desmontaje (Terraform, CLI, CloudFormation y consola web), consulta `guia_limpieza.md`.
