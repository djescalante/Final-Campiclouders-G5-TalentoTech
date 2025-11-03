# 🌐 Guía Visual de Aprendizaje Terraform  
**Proyecto:** Elastic Beanstalk + DynamoDB + IAM + S3  
**Objetivo:** Comprender y practicar infraestructura como código tomando como base `main.tf`, `variables.tf` y `outputs.tf`.

---

## 1. Primer vistazo al mapa mental

```
┌──────────────────┐
│  terraform init  │
└──────┬───────────┘
       │ requiere proveedores (aws, archive)
┌──────▼───────────┐
│  terraform plan  │
└──────┬───────────┘
       │ genera plan tfplan
┌──────▼───────────┐
│ terraform apply  │
└──────┬───────────┘
       │ crea recursos
       ▼
┌─────────────────────────────────────────────┐
│                 AWS Account                  │
│ ┌───────────┐  ┌────────────┐  ┌──────────┐ │
│ │ DynamoDB  │  │ Elastic     │  │   S3     │ │
│ │ contacts  │  │ Beanstalk   │  │ bucket   │ │
│ │ hash=id   │  │ app+env     │  │ app zip  │ │
│ └───────────┘  └────────────┘  └──────────┘ │
│       ▲                ▲              ▲       │
│       │                │              │       │
│   IAM policy       IAM roles      archive_file │
└─────────────────────────────────────────────┘
```

Así se conectan las piezas: el módulo Terraform orquesta los servicios de AWS y empaqueta el código listo para Elastic Beanstalk.

---

## 2. Ruta de aprendizaje recomendada

```
[0] Preparar entorno ─► [1] Variables y providers ─► [2] IAM + Seguridad
            │                      │                        │
            ▼                      ▼                        ▼
     (terraform.tfvars)      (main.tf:1-36)           (main.tf:42-120)

┌───────────────────────────────────────────────────────────────────┐
│ [3] Almacenamiento       │ [4] Elastic Beanstalk │ [5] Outputs    │
│   S3 + archive_file      │   settings + deploy   │   (eb URL, ARN)│
└───────────────────────────────────────────────────────────────────┘
```

Estudia cada bloque, reproduciendo el recorrido en tu editor y saltando a las líneas indicadas.

---

## 3. Fichas rápidas de los componentes

| Componente                | Ubicación         | ¿Qué aprender?                                                | Micro-reto                                           |
|---------------------------|-------------------|----------------------------------------------------------------|------------------------------------------------------|
| Provider AWS              | `main.tf:1-23`    | Fijar versiones y región según `variables.tf`                  | Cambia `var.region` y observa el `plan`              |
| DynamoDB `contacts`       | `main.tf:27-37`   | Crear tabla con `PAY_PER_REQUEST` y atributo hash              | Añade un `tags` para practicar gobierno              |
| IAM Role EC2              | `main.tf:42-88`   | Definir `assume_role_policy` y política mínima DynamoDB        | Limita la política solo a acciones necesarias        |
| S3 Bucket deploy          | `main.tf:125-152` | Generar nombre dinámico con `data.aws_caller_identity` y ZIP   | Activa `versioning` y `server_side_encryption`       |
| EB Application+Environment| `main.tf:157-259` | Relacionar `solution_stack`, `settings` y perfiles IAM         | Agrega `HealthCheckPath` custom y `tags`             |
| Variables públicas        | `variables.tf`    | Declarar defaults y documentación                              | Protege `cors_origin` con valor seguro en `tfvars`   |
| Outputs                   | `outputs.tf`      | Exponer ARN y CNAME tras el `apply`                            | Añade un output para el bucket de despliegue         |

---

## 4. Recorriendo el código paso a paso

### 4.1 Bloque Terraform y proveedores
- **`main.tf:1-17`** define versiones mínimas (`>= 1.0.0`) y los proveedores `aws` y `archive`.  
- **Aprendizaje clave:** usar versiones fijas evita sorpresas al replicar el laboratorio.

### 4.2 Datos dinámicos
- **`data "aws_caller_identity"`** (`main.tf:22`) obtiene el ID de cuenta; se usa luego en el nombre del bucket para garantizar unicidad.
- **`data "archive_file" "app"`** (`main.tf:141-145`) empaqueta la carpeta `app/` en cada `apply`, útil para automatizar despliegues.

### 4.3 Seguridad e identidades
- **`aws_iam_role` + `aws_iam_role_policy`** (`main.tf:42-120`) muestran cómo dar permisos mínimos al EC2 de Elastic Beanstalk y adjuntar políticas gestionadas.
- **Dato útil:** revisa `jsonencode({ ... })` para mantener las políticas legibles dentro de HCL.

### 4.4 Almacenamiento de artefactos
- **`aws_s3_bucket` `eb_deployments`** (`main.tf:125`) genera un bucket específico por cuenta.
- Añade en tu práctica:
  ```hcl
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  ```

### 4.5 Elastic Beanstalk de extremo a extremo
- **`aws_elastic_beanstalk_application`** y `environment` (`main.tf:157-259`) crean la aplicación Node.js 20 con variables de entorno (`TABLE_NAME`, `CORS_ORIGIN`, `NODE_ENV`, `AWS_REGION`).
- Importante: `IamInstanceProfile` y `ServiceRole` enlazan los roles creados en secciones anteriores; sin ellos el despliegue falla.

---

## 5. Simulación de comandos esenciales

### 5.1 Inicialización
```bash
$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.1"...
- Installing hashicorp/aws v5.49.0...
- Installing hashicorp/archive v2.4.0...

Terraform has been successfully initialized!
```

### 5.2 Plan
```bash
$ terraform plan -out=tfplan
Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + dynamodb_table_arn    = (known after apply)
  + eb_environment_cname  = (known after apply)
```

### 5.3 Apply (extracto)
```bash
$ terraform apply "tfplan"
aws_dynamodb_table.contacts: Creating...
aws_s3_bucket.eb_deployments: Creating...
aws_elastic_beanstalk_environment.env: Creating...

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
dynamodb_table_arn   = "arn:aws:dynamodb:us-east-1:123456789012:table/ContactosCampiclouders"
eb_environment_cname = "eb-dynamo-env.eba-xyz123.us-east-1.elasticbeanstalk.com"
```

### 5.4 Destroy (recuerda vaciar el bucket si no usas `force_destroy`)
```bash
$ terraform destroy
Plan: 0 to add, 0 to change, 8 to destroy.

Destroy complete! Resources: 8 destroyed.
```

---

## 6. Laboratorio guiado

1. **Prepara tu `terraform.tfvars`:**
   ```hcl
   region      = "us-east-1"
   app_name    = "EB-Dynamo"
   env_name    = "eb-dynamo-env"
   table_name  = "ContactosCampiclouders"
   cors_origin = "https://tu-frontend"
   instance_type = "t3.micro"
   ```

2. **Ejecuta el ciclo básico:** `init → plan → apply`.

3. **Verifica en AWS:** abre Elastic Beanstalk y DynamoDB para comprobar recursos.

4. **Despliega la app:** sube el ZIP creado en `app-deploy.zip` o usa EB CLI (`eb deploy`).

5. **Limpia:** `terraform destroy` y elimina objetos S3 restantes si hace falta.

---

## 7. Desafíos para afianzar conocimientos

- **Etiquetado:** agrega un bloque `tags` común a DynamoDB, S3 y Elastic Beanstalk para practicar consistencia.
- **Cifrado:** habilita SSE en el bucket de despliegues y vuelve a ejecutar `plan`.
- **Módulos:** intenta extraer la definición de DynamoDB/IAM en un módulo local y reutilízalo.
- **Validaciones:** crea reglas `terraform validate` añadiendo `variables` con `validation` para que `cors_origin` no permita `*` en producción.

---

## 8. Checklist final

- [ ] `terraform.tfvars` personalizado (sin `cors_origin = "*"`)
- [ ] `terraform init` ejecutado sin errores
- [ ] `plan` revisado antes de aplicar
- [ ] Roles IAM con políticas mínimas (`ddb_basic_access`)
- [ ] Bucket de despliegues con versionado/cifrado (extra recomendado)
- [ ] `terraform destroy` probado y bucket limpio

---

## 9. Próximos pasos sugeridos

1. Automatiza el flujo con un pipeline (GitHub Actions o CodePipeline) que ejecute `terraform fmt`, `validate`, `plan` y `apply`.
2. Añade monitoreo: integra `CloudWatch Logs` y alarmas con Terraform para visualizar métricas del entorno EB.
3. Experimenta con otro entorno (QA/Prod) duplicando el estado mediante `workspaces` o variables por entorno.

---

¿Listo para seguir? Avanza al reto modularizando la configuración o añade pruebas automáticas para el backend. ¡Terraform se aprende practicando!
