 CLI (outside of core workflow)
5. Interact with Terraform modules
6. Navigate Terraform workflow
7. Implement and maintain state
8. Read, generate, and modify configuration
9. Understand Terraform Cloud and Enterprise capabilities

**Preparación:**
```bash
# Practica los comandos esenciales
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
terraform fmt
terraform state list
terraform state show
terraform output
terraform workspace list

# Estudia los conceptos clave
- Providers y recursos
- Variables y outputs
- State management
- Módulos
- Backend configuration
```

**Recursos de estudio:**
- HashiCorp Learn: https://learn.hashicorp.com/terraform
- Practice Exams: https://www.udemy.com/terraform-associate/
- Study Guide: https://www.terraform.io/docs/cloud/guides/recommended-practices/

---

## 🎨 Plantillas Útiles

### Template Completo de Proyecto

```hcl
# ═══════════════════════════════════════════════════════
# terraform.tf
# ═══════════════════════════════════════════════════════
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend remoto (opcional)
  # backend "s3" {
  #   bucket         = "mi-terraform-state"
  #   key            = "proyecto/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

# ═══════════════════════════════════════════════════════
# providers.tf
# ═══════════════════════════════════════════════════════
provider "aws" {
  region = var.region
  
  default_tags {
    tags = local.common_tags
  }
}

# ═══════════════════════════════════════════════════════
# locals.tf
# ═══════════════════════════════════════════════════════
locals {
  common_tags = {
    Proyecto    = var.proyecto
    Ambiente    = var.ambiente
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
    CreatedDate = timestamp()
  }
  
  name_prefix = "${var.proyecto}-${var.ambiente}"
}

# ═══════════════════════════════════════════════════════
# variables.tf
# ═══════════════════════════════════════════════════════
variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "ambiente" {
  description = "Ambiente de despliegue"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.ambiente)
    error_message = "Ambiente debe ser: dev, staging o prod."
  }
}

variable "owner_email" {
  description = "Email del dueño del proyecto"
  type        = string
}

variable "cost_center" {
  description = "Centro de costos"
  type        = string
  default     = "Engineering"
}

# ═══════════════════════════════════════════════════════
# outputs.tf
# ═══════════════════════════════════════════════════════
output "region" {
  description = "Región de AWS utilizada"
  value       = var.region
}

output "ambiente" {
  description = "Ambiente desplegado"
  value       = var.ambiente
}

output "recursos_creados" {
  description = "Lista de recursos principales creados"
  value = {
    proyecto = var.proyecto
    region   = var.region
    ambiente = var.ambiente
  }
}

# ═══════════════════════════════════════════════════════
# terraform.tfvars
# ═══════════════════════════════════════════════════════
region      = "us-east-1"
proyecto    = "MiProyecto"
ambiente    = "dev"
owner_email = "tu-email@ejemplo.com"
cost_center = "Engineering"
```

---

### Template de Módulo

```
modules/mi-modulo/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

**versions.tf:**
```hcl
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

**variables.tf:**
```hcl
variable "nombre" {
  description = "Nombre del recurso"
  type        = string
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}
```

**outputs.tf:**
```hcl
output "id" {
  description = "ID del recurso creado"
  value       = aws_resource.example.id
}

output "arn" {
  description = "ARN del recurso creado"
  value       = aws_resource.example.arn
}
```

**README.md:**
```markdown
# Módulo: Mi Módulo

## Descripción
Breve descripción del módulo.

## Uso

```hcl
module "ejemplo" {
  source = "./modules/mi-modulo"
  
  nombre = "mi-recurso"
  tags = {
    Proyecto = "MiProyecto"
  }
}
```

## Inputs

| Nombre | Descripción | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| nombre | Nombre del recurso | string | - | sí |
| tags | Tags adicionales | map(string) | {} | no |

## Outputs

| Nombre | Descripción |
|--------|-------------|
| id | ID del recurso |
| arn | ARN del recurso |
```

---

## 🔍 Debugging y Troubleshooting Avanzado

### 1. **Habilitar Logs Detallados**

```bash
# Nivel de logs
export TF_LOG=TRACE  # Más detallado
export TF_LOG=DEBUG
export TF_LOG=INFO
export TF_LOG=WARN
export TF_LOG=ERROR

# Guardar logs en archivo
export TF_LOG_PATH=./terraform.log

# Ejecutar con logs
terraform apply

# Ver logs
cat terraform.log
```

---

### 2. **Debugging del State**

```bash
# Ver todo el state en formato legible
terraform show

# Ver state en formato JSON
terraform show -json | jq .

# Ver un recurso específico
terraform state show aws_dynamodb_table.contacts

# Listar todos los recursos
terraform state list

# Buscar recursos por patrón
terraform state list | grep dynamodb
```

---

### 3. **Inspeccionar Plan**

```bash
# Generar plan y guardarlo
terraform plan -out=tfplan

# Ver plan en formato legible
terraform show tfplan

# Ver plan en JSON
terraform show -json tfplan | jq .

# Ver solo los cambios
terraform show tfplan | grep -A 10 "will be created"
```

---

### 4. **Debugging de Variables**

```hcl
# Agregar outputs temporales para debug
output "debug_variables" {
  value = {
    region       = var.region
    app_name     = var.app_name
    table_name   = var.table_name
    instance_type = var.instance_type
  }
}

output "debug_locals" {
  value = {
    common_tags = local.common_tags
    name_prefix = local.name_prefix
  }
}
```

---

### 5. **Problemas Comunes y Soluciones**

#### Error: "Error locking state"

**Problema:**
```
Error: Error locking state: Error acquiring the state lock
```

**Causa:** Otro proceso está usando el state o hubo un crash anterior.

**Solución:**
```bash
# Ver locks activos
terraform force-unlock <LOCK_ID>

# Si usas DynamoDB para locks
aws dynamodb scan --table-name terraform-lock
```

---

#### Error: "Provider configuration not present"

**Problema:**
```
Error: Provider configuration not present
```

**Solución:**
```bash
# Reinstalar providers
rm -rf .terraform/
terraform init
```

---

#### Error: "Cycle" en dependencias

**Problema:**
```
Error: Cycle: aws_iam_role.a, aws_iam_role.b
```

**Causa:** Dependencia circular (A depende de B, B depende de A).

**Solución:**
```hcl
# Romper la dependencia circular reorganizando el código
# o usando depends_on explícitamente en uno solo
```

---

## 📊 Comparativa: Terraform vs Otras Herramientas

```
┌─────────────────────────────────────────────────────────────┐
│                    TERRAFORM VS OTROS                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  TERRAFORM vs CLOUDFORMATION                                │
│  ────────────────────────────                               │
│  ✅ Multi-cloud (AWS, Azure, GCP)                           │
│  ✅ Lenguaje HCL (más legible que JSON/YAML)                │
│  ✅ State management robusto                                │
│  ✅ Ecosistema de módulos amplio                            │
│  ❌ No nativo de AWS (CloudFormation sí)                    │
│                                                             │
│  TERRAFORM vs ANSIBLE                                       │
│  ────────────────────────                                   │
│  ✅ Mejor para infraestructura (Ansible para config)        │
│  ✅ Declarativo vs Imperativo                               │
│  ✅ State tracking automático                               │
│  ❌ No ejecuta comandos en servidores                       │
│                                                             │
│  TERRAFORM vs PULUMI                                        │
│  ─────────────────────────                                  │
│  ✅ Sintaxis estándar (HCL)                                 │
│  ✅ Más maduro y adoptado                                   │
│  ❌ No permite programación completa (Pulumi sí)            │
│                                                             │
│  TERRAFORM vs CDK (AWS)                                     │
│  ──────────────────────────                                 │
│  ✅ Multi-cloud                                             │
│  ✅ No requiere compilación                                 │
│  ❌ CDK usa lenguajes reales (TypeScript, Python)           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Roadmap de Aprendizaje

### Semana 1-2: Fundamentos
```
□ Instalar Terraform
□ Completar tutoriales básicos de HashiCorp Learn
□ Crear primer recurso (S3 bucket)
□ Entender init, plan, apply, destroy
□ Practicar con variables y outputs
```

### Semana 3-4: Recursos AWS
```
□ Crear DynamoDB table
□ Configurar IAM roles y policies
□ Desplegar aplicación en Elastic Beanstalk
□ Integrar múltiples recursos
□ Entender dependencias
```

### Semana 5-6: Conceptos Intermedios
```
□ Usar locals y conditionals
□ Implementar dynamic blocks
□ Crear primer módulo
□ Configurar remote state (S3)
□ Usar workspaces
```

### Semana 7-8: Conceptos Avanzados
```
□ Multi-region deployment
□ Implementar CI/CD con GitHub Actions
□ Crear módulos reutilizables
□ Implementar testing con Terratest
□ Configurar monitoring completo
```

### Semana 9-10: Proyectos Reales
```
□ Migrar infraestructura existente
□ Implementar disaster recovery
□ Configurar auto-scaling
□ Optimizar costos
□ Documentar todo
```

---

## 🏅 Proyecto Capstone: Aplicación Completa

### Objetivo
Crear una aplicación web full-stack con todas las mejores prácticas.

### Arquitectura
```
┌─────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA FINAL                       │
└─────────────────────────────────────────────────────────────┘

                        🌐 Route 53
                             │
                             ↓
                    ┌─────────────────┐
                    │  CloudFront     │ (CDN)
                    │  + WAF          │ (Firewall)
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ↓                             ↓
    ┌──────────────────┐          ┌──────────────────┐
    │  S3 (Frontend)   │          │  ALB             │
    │  React/Vue       │          │  (Load Balancer) │
    └──────────────────┘          └────────┬─────────┘
                                           │
                        ┌──────────────────┼──────────────────┐
                        ↓                  ↓                  ↓
                 ┌─────────────┐    ┌─────────────┐   ┌─────────────┐
                 │  EB Env 1   │    │  EB Env 2   │   │  EB Env 3   │
                 │  (AZ-1a)    │    │  (AZ-1b)    │   │  (AZ-1c)    │
                 └──────┬──────┘    └──────┬──────┘   └──────┬──────┘
                        │                  │                  │
                        └──────────────────┼──────────────────┘
                                           │
                        ┌──────────────────┼──────────────────┐
                        ↓                  ↓                  ↓
                 ┌─────────────┐    ┌─────────────┐   ┌─────────────┐
                 │  DynamoDB   │    │  ElastiCache│   │     S3      │
                 │  (Database) │    │  (Redis)    │   │  (Storage)  │
                 └─────────────┘    └─────────────┘   └─────────────┘
                        │                  │                  │
                        └──────────────────┼──────────────────┘
                                           ↓
                                    ┌─────────────┐
                                    │  CloudWatch │
                                    │  + X-Ray    │
                                    │  (Monitor)  │
                                    └─────────────┘
```

### Implementación

**1. Estructura de Carpetas**
```
proyecto-final/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/
│   │   ├── networking/
│   │   ├── compute/
│   │   ├── database/
│   │   ├── storage/
│   │   ├── cdn/
│   │   ├── monitoring/
│   │   └── security/
│   └── global/
├── app/
│   ├── frontend/
│   └── backend/
├── .github/
│   └── workflows/
└── docs/
```

**2. Módulo de Networking**
```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Type = "Public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Type = "Private"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}
```

**3. Módulo de Seguridad**
```hcl
# modules/security/main.tf

# WAF para CloudFront
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.name_prefix}-waf"
  scope = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  # Rate limiting
  rule {
    name     = "rate-limit"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled  = true
    }
  }
  
  # Bloquear IPs sospechosas
  rule {
    name     = "block-bad-ips"
    priority = 2
    
    action {
      block {}
    }
    
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "${var.name_prefix}-blocked-ips"
      sampled_requests_enabled  = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.name_prefix}-waf"
    sampled_requests_enabled  = true
  }
}

resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${var.name_prefix}-blocked-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
  })
}
```

**4. Módulo de Monitoring Completo**
```hcl
# modules/monitoring/main.tf

# SNS Topic para alertas críticas
resource "aws_sns_topic" "critical" {
  name = "${var.name_prefix}-critical-alerts"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "critical_email" {
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = var.critical_alert_email
}

resource "aws_sns_topic_subscription" "critical_sms" {
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "sms"
  endpoint  = var.critical_alert_phone
}

# Dashboard completo
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # Salud general
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "EnvironmentHealth"],
            ["AWS/ApplicationELB", "HealthyHostCount"],
            ["AWS/ApplicationELB", "UnHealthyHostCount"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Application Health"
        }
      },
      # Performance
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime"],
            ["AWS/ElasticBeanstalk", "ApplicationLatencyP99"],
            ["AWS/ElasticBeanstalk", "ApplicationLatencyP95"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Response Time"
        }
      },
      # Errores
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "HTTP Errors"
        }
      },
      # DynamoDB
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", { stat = "Sum" }],
            ["AWS/DynamoDB", "UserErrors", { stat = "Sum" }]
          ]
          period = 300
          region = var.region
          title  = "DynamoDB Metrics"
        }
      },
      # Costos estimados
      {
        type   = "metric"
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", { stat = "Maximum" }]
          ]
          period = 86400
          region = "us-east-1"
          title  = "Estimated Costs (USD)"
        }
      }
    ]
  })
}

# Alarmas
resource "aws_cloudwatch_metric_alarm" "critical_errors" {
  alarm_name          = "${var.name_prefix}-critical-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "Alerta crítica: Más de 50 errores 5xx en 10 minutos"
  alarm_actions       = [aws_sns_topic.critical.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.name_prefix}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2.0
  alarm_description   = "Latencia promedio mayor a 2 segundos"
  alarm_actions       = [aws_sns_topic.critical.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Al menos un host no está saludable"
  alarm_actions       = [aws_sns_topic.critical.arn]
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  alarm_name          = "${var.name_prefix}-dynamodb-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "DynamoDB está siendo throttled"
  alarm_actions       = [aws_sns_topic.critical.arn]
}

# Log Insights Queries
resource "aws_cloudwatch_query_definition" "errors" {
  name = "${var.name_prefix}-error-analysis"
  
  log_group_names = [var.log_group_name]
  
  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count() by bin(5m)
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${var.name_prefix}-slow-requests"
  
  log_group_names = [var.log_group_name]
  
  query_string = <<-QUERY
    fields @timestamp, @message
    | filter duration > 1000
    | sort duration desc
    | limit 20
  QUERY
}
```

---

## 🎉 ¡Felicidades!

Has completado la guía completa de Terraform. Ahora tienes:

✅ **Conocimiento sólido** de Infrastructure as Code
✅ **Experiencia práctica** con AWS y Terraform
✅ **Proyecto real** desplegado y funcionando
✅ **Best practices** implementadas
✅ **Habilidades** para trabajar en proyectos enterprise

### Siguiente Paso

```
🚀 Aplica lo aprendido en proyectos reales
📚 Continúa aprendiendo con proyectos más complejos
🤝 Comparte tu conocimiento con otros
💼 Úsalo en tu trabajo diario
🎓 Considera certificarte en Terraform
```

---

## 📞 Soporte y Comunidad

```
💬 Preguntas: HashiCorp Discuss Forum
🐛 Bugs: GitHub Issues de Terraform
📖 Docs: terraform.io/docs
🎓 Learn: learn.hashicorp.com
💼 Jobs: Terraform skills son muy demandadas
```

---

**¡Mucho éxito en tu viaje con Terraform!** 🎊

---

*Guía creada con ❤️ para el proyecto EB+Dynamo - PDN*
*Última actualización: Octubre 2025*
