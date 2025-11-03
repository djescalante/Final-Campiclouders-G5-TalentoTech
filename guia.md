# 🚀 Presentación del Proyecto: Aplicación Full Stack en AWS con Elastic Beanstalk y DynamoDB

Este documento describe una aplicación web full stack desplegada en AWS, diseñada no solo para ser funcional, sino también para servir como un ejemplo de **excelencia en ingeniería de software en la nube**.

---

## 🎯 ¿Qué es este proyecto?

Es una aplicación completa que permite a los usuarios registrarse a través de un formulario web. Los datos se procesan mediante un backend en Node.js y se almacenan de forma segura en una base de datos NoSQL (DynamoDB).

El objetivo principal es demostrar un flujo de despliegue profesional en AWS, integrando:
- **Frontend:** Un sitio estático con HTML y CSS.
- **Backend:** Una API REST con Node.js y Express.
- **Base de Datos:** Amazon DynamoDB, gestionada como un servicio serverless.
- **Plataforma:** AWS Elastic Beanstalk para una gestión automatizada de la infraestructura.

---

## 🧱 Arquitectura y Componentes

El flujo de la aplicación es simple pero robusto:
1.  Un usuario completa el formulario en el sitio web.
2.  Los datos se envían a un endpoint `POST /registro` en el backend.
3.  La aplicación Node.js, utilizando el SDK de AWS, valida y persiste los datos en una tabla de DynamoDB.
4.  Todo el entorno es gestionado por Elastic Beanstalk, que se encarga del balanceo de carga, el auto-scaling (si se configura) y la salud de las instancias.

| Componente | Tecnología | Propósito |
|---|---|---|
| 🖥️ **Frontend** | HTML + CSS | Interfaz de usuario para la captura de datos. |
| ⚙️ **Backend** | Node.js + Express | API para procesar y almacenar la información. |
| 🗄️ **Base de Datos** | Amazon DynamoDB | Almacenamiento NoSQL, escalable y sin servidor. |
| ☁️ **Plataforma** | AWS Elastic Beanstalk | Orquestación y despliegue automatizado (PaaS). |
| 🔐 **Seguridad** | AWS IAM | Roles y políticas con privilegios mínimos. |
| 📦 **Artefactos** | Amazon S3 | Almacenamiento seguro para los paquetes de la aplicación. |

---
## 🏆 Mejores Prácticas Implementadas
Este proyecto va más allá de la funcionalidad, incorporando principios clave de ingeniería de software moderna.
### 1. Infraestructura como Código (IaC)
La infraestructura es versionable, repetible y auditable. Se proporcionan plantillas para tres métodos de despliegue, demostrando flexibilidad y dominio del ecosistema AWS:
- **Terraform:** Para una gestión declarativa y multi-nube (`main.tf`).
- **AWS CloudFormation:** Para una integración nativa con AWS (`cloudformation/eb-dynamo.yml`).
- **AWS CLI:** Para scripting y automatización (`guia_cli.md`).

### 2. Seguridad por Diseño (Security by Design)
- **Principio de Menor Privilegio:** El rol IAM de la instancia EC2 solo tiene permisos para las acciones de DynamoDB estrictamente necesarias (`PutItem`, `GetItem`, etc.), en lugar de un `dynamodb:*` genérico.
- **Roles de Instancia:** No se almacenan credenciales (claves de acceso) en el código. La aplicación las obtiene de forma segura a través del perfil de instancia IAM.
- **Bucket S3 Privado:** El bucket que almacena los artefactos de despliegue bloquea todo el acceso público por defecto.

### 3. Automatización y DevOps
- **Servicio Gestionado (PaaS):** El uso de Elastic Beanstalk abstrae la complejidad de gestionar servidores, parches, balanceadores y escalado.
- **Empaquetado Automático:** El código de Terraform usa el proveedor `archive` para crear el `.zip` de la aplicación en el momento del despliegue, asegurando la consistencia entre la infraestructura y el código.

### 4. Optimización de Costos
- **Pago por Uso:** La tabla de DynamoDB está configurada en modo `PAY_PER_REQUEST`, ideal para cargas de trabajo variables o de bajo tráfico, eliminando costos de capacidad ociosa.
- **Instancias de Bajo Costo:** Se utiliza `t3.micro` por defecto, que es parte de la capa gratuita de AWS y es eficiente para desarrollo y pruebas.
- **Guías de Limpieza:** Se proporciona una `guia_limpieza.md` centralizada con comandos para destruir todos los recursos, evitando costos inesperados.

### 5. Documentación Excepcional
El proyecto está documentado de manera exhaustiva para facilitar su comprensión, uso y aprendizaje:
- **Guías de Despliegue Detalladas:** Para cada método (Terraform, CLI, CloudFormation).
- **Diagramas de Arquitectura:** Diagramas UML para visualizar casos de uso, componentes, secuencias y el modelo de despliegue.
- **Guía de Aprendizaje Visual:** La `guia_terraform.md` incluye un mapa mental y "micro-retos" para facilitar la comprensión de IaC.

---

## 📊 Monitoreo y Observabilidad

El entorno de Elastic Beanstalk está configurado para utilizar **"Salud Mejorada" (Enhanced Health)**. Esto proporciona métricas detalladas del sistema operativo y la aplicación que van más allá de un simple "OK/FAIL", incluyendo:
- **Métricas del SO:** Carga de la CPU, memoria, etc.
- **Métricas de la Aplicación:** Latencia (p50, p90, p99), códigos de estado HTTP (2xx, 4xx, 5xx).
- **Logs Centralizados:** Los logs de la aplicación y del servidor web se pueden transmitir a CloudWatch Logs para su análisis y depuración.

Esta base se puede extender fácilmente con Terraform para incluir un **dashboard de CloudWatch** y **alarmas** que notifiquen sobre errores 5xx, alta latencia o instancias no saludables.

---
## 🚀 ¿Cómo empezar?

El proyecto ofrece múltiples guías para que puedas desplegarlo según tu herramienta preferida:
- **`README.md`**: Contiene las instrucciones básicas de instalación local y despliegue con la EB CLI.
- **`guia_terraform.md`**: Una guía visual y pedagógica para desplegar con Terraform.
- **`guia_cli.md`**: Pasos detallados para un despliegue completo usando solo la AWS CLI.
- **`guia_cloudformation.md`**: Instrucciones para usar la plantilla de CloudFormation.

---

## 🧹 Limpieza

Para evitar costos, no olvides destruir todos los recursos una vez que hayas terminado tus pruebas. Consulta `guia_limpieza.md` para obtener instrucciones consolidadas y seguras.
