# ☁️ Proyecto EB + DynamoDB – CampiClouders

### 🚀 Descripción General
Este proyecto implementa una **aplicación web full stack en AWS**, que integra:

- **Frontend:** Sitio estático con formulario de registro (HTML + CSS).
- **Backend:** API REST construida en **Node.js + Express**.
- **Base de datos:** **DynamoDB** como servicio NoSQL en la nube.
- **Despliegue:** **AWS Elastic Beanstalk**, con integración automática del backend y el frontend.

El objetivo es **demostrar un flujo completo de registro de usuarios** en AWS, aplicando buenas prácticas de infraestructura y despliegue cloud.

---

## 🧱 Arquitectura del Proyecto

El flujo general es:

1. El usuario llena el formulario web.
2. El formulario envía los datos al endpoint `/registro` del backend (Node.js).
3. El backend inserta el registro en **DynamoDB** usando el SDK oficial de AWS.
4. Elastic Beanstalk gestiona la infraestructura y las variables de entorno.
5. Los datos pueden consultarse directamente desde la consola DynamoDB.

---

## 🗂️ Estructura de Archivos

```
EB+Dynamo/
├── main.tf              # (opcional) Ejemplo IaC con Terraform
├── server.js            # Servidor Express + conexión a DynamoDB
├── package.json         # Dependencias y scripts de ejecución
├── public/
│   ├── index.html       # Sitio web principal + formulario de registro
│   └── style.css        # Estilos del frontend
├── guia.md              # Guía de despliegue paso a paso
└── diagrams/
    ├── usecase.png
    ├── sequence.png
    ├── data_model.png
    ├── components.png
    └── deployment.png
```

---

## 🧩 Tecnologías Usadas

| Componente | Tecnología | Descripción |
|-------------|-------------|-------------|
| 🖥️ Frontend | HTML + CSS | Formulario dinámico y responsive |
| ⚙️ Backend | Node.js + Express | API REST que gestiona el registro |
| 🗄️ Base de Datos | Amazon DynamoDB | Almacenamiento NoSQL sin servidor |
| ☁️ Despliegue | AWS Elastic Beanstalk | Automatización de infraestructura |
| 🔐 Permisos | IAM Policies | Control de acceso para DynamoDB |
| 🧠 SDK AWS | @aws-sdk v3 | Conexión directa al servicio DynamoDB |

---

## 🧰 Instalación Local (modo desarrollo)

1. Clona el repositorio:
   ```bash
   git clone https://github.com/djescalante/campiclouders-web-aws-m03.git
   cd EB-Dynamo
   ```

2. Instala las dependencias:
   ```bash
   npm install
   ```

3. Crea un archivo `.env` (opcional) con:
   ```bash
   TABLE_NAME=ContactosCampiclouders
   CORS_ORIGIN=http://localhost:8080
   ```

4. Ejecuta el servidor:
   ```bash
   npm start
   ```

5. Abre [http://localhost:8080](http://localhost:8080) y prueba el formulario.

---

## 🌩️ Despliegue en AWS Elastic Beanstalk

1. Instala la CLI:
   ```bash
   pip install awsebcli --user
   ```

2. Inicializa el entorno:
   ```bash
   eb init -p node.js-20 EB-Dynamo
   ```

3. Crea o usa el ambiente:
   ```bash
   # Si ya existe por Terraform:  eb use eb-dynamo-env
   # Si no existe aún:            eb create eb-dynamo-env --single --instance_types t3.micro
   ```

4. Configura variables en el panel de **Configuration → Software**:
   ```
   TABLE_NAME=ContactosCampiclouders
   CORS_ORIGIN=https://TU-ORIGEN
   ```

5. Abre la aplicación:
   ```bash
   eb open
   ```

---

## 🧾 Ejemplo de Tabla DynamoDB

| id (PK) | nombres | apellido | email | celular | interes | createdAt |
|----------|----------|-----------|---------|----------|-----------|-------------|
| `uuid` | Ana | Pérez | ana@correo.com | 3000000000 | curso-aws | 2025-10-29T15:00:00Z |

---

## 🧹 Limpieza del Laboratorio

Para eliminar los recursos creados:

```bash
eb terminate eb-dynamo-env
aws dynamodb delete-table --table-name ContactosCampiclouders
```

---

## 📊 Diagramas del Proyecto

| Tipo | Imagen |
|------|--------|
| 🧩 Componentes | ![components](./docs/uml/components.png) |
| 🔁 Secuencia | ![sequence](./docs/uml/sequence.png) |
| 💾 Modelo de Datos | ![data_model](./docs/uml/data_model.png) |
| 🧭 Casos de Uso | ![usecase](./docs/uml/usecase.png) |
| ☁️ Despliegue | ![deployment](./docs/uml/deployment.png) |

---

## 👥 Equipo CampiClouders

| Integrante | Rol |
|-------------|-----|
| José David Escalante | Arquitecto / Desarrollador |
| Integrante 2 | Backend |
| Integrante 3 | Frontend |
| Integrante 4 | DevOps |
| Integrante 5 | QA / Documentación |

---

## 💬 Conclusión

Este proyecto demuestra una **integración completa entre un backend Node.js y DynamoDB**, desplegado automáticamente con **Elastic Beanstalk**, aplicando prácticas reales de infraestructura como código y despliegue en la nube.  
Es ideal como laboratorio educativo y punto de partida para soluciones sin servidor (serverless) en AWS.

---

📘 **Autor:** CampiClouders Team  
🗓️ **Bootcamp Cloud & DevOps 2025**  
☁️ *CampiClouders – Innovación desde la Nube*

---

## 🔗 Limpieza avanzada
Para una guía consolidada de desmontaje (Terraform, CLI, CloudFormation, consola web), consulta `guia_limpieza.md`.

---

## 🧱 Infraestructura como Código (Terraform)

El repo incluye archivos Terraform para crear:
- DynamoDB (tabla `ContactosCampiclouders`).
- Elastic Beanstalk Application + Environment (Node.js 20 / AL2023).
- IAM para acceso mínimo a DynamoDB desde EC2 del EB.

Pasos básicos:
```
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```
Requisitos:
- Define `platform_arn` en `terraform.tfvars` (ver `guia_terraform.md`).
- Si `aws-elasticbeanstalk-ec2-role` ya existe, ajusta `eb_ec2_role_name` o importa recursos.
