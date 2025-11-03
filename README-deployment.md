# ⚡ Despliegue — EB + DynamoDB

Aplicación Node.js (Express) en **Elastic Beanstalk** con persistencia en **DynamoDB**. El frontend estático vive en `/public` y el backend expone `POST /registro`.

---

## ✅ Variables de entorno en EB
- `TABLE_NAME=ContactosCampiclouders`
- `CORS_ORIGIN=https://TU-DOMINIO` (o `*` en pruebas)

---

## ▶️ Opción 1: Terraform + EB CLI (recomendada)
1) Ajusta `terraform.tfvars` y define un `platform_arn` válido de Node.js 20 AL2023.
2) Provisiona:
```
terraform init
terraform apply
```
3) Despliega la app:
```
npm install
pip install --user awsebcli
eb init -p node.js-20 EB-Dynamo
eb use eb-dynamo-env
eb deploy
```

---

## ▶️ Opción 2: Solo EB CLI
```
npm install
pip install --user awsebcli
eb init -p node.js-20 EB-Dynamo
eb create eb-dynamo-env --single --instance_types t3.micro
eb open
```
Luego, añade las variables en Configuration → Software.

---

## ✅ Prueba rápida
1) Abre la URL (CNAME) del ambiente EB.
2) Envía el formulario de la home; por defecto hace POST a `/registro`.
3) Verifica el ítem creado en DynamoDB.

---

## 🔗 Limpieza avanzada
Para un teardown completo por método (Terraform, CLI, CloudFormation o consola web), revisa `guia_limpieza.md`.
