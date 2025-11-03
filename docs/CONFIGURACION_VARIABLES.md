# ⚠️ IMPORTANTE - Configuración de Variables

## 📁 Archivos de Configuración

Tu proyecto tiene dos archivos de variables:

### 1. `terraform.tfvars.example` ✅ (Para GitHub)
- **Propósito**: Plantilla de ejemplo para otros desarrolladores
- **Contenido**: Valores de ejemplo y documentación
- **Git**: ✅ **SÍ se sube** a GitHub
- **Uso**: Otros desarrolladores lo copian como punto de partida

### 2. `terraform.tfvars` 🔐 (Tu archivo real)
- **Propósito**: Configuración real con tus datos
- **Contenido**: Valores reales, emails, configuraciones personales
- **Git**: ❌ **NO se sube** a GitHub (protegido por `.gitignore`)
- **Uso**: Solo tú lo usas localmente

---

## 🚀 Configuración Inicial

### Para ti (primera vez):

```bash
# El archivo terraform.tfvars ya existe con valores por defecto
# Solo necesitas actualizarlo con tu email:

code terraform.tfvars

# Cambiar esta línea:
alert_email = ""

# Por tu email real:
alert_email = "tu-email@ejemplo.com"
```

### Para otros desarrolladores:

```bash
# 1. Clonar el repositorio
git clone <tu-repo>

# 2. Copiar el ejemplo
cp terraform.tfvars.example terraform.tfvars

# 3. Editar con sus valores
code terraform.tfvars
```

---

## 🔐 Seguridad

### ✅ Lo que ESTÁ protegido:

```bash
# .gitignore incluye:
*.tfvars          # ← Protege terraform.tfvars
*.tfstate         # ← Protege el estado
*.tfstate.backup  # ← Protege backups
.env              # ← Protege variables de entorno
```

### ⚠️ Lo que DEBE subirse a GitHub:

```bash
terraform.tfvars.example  # ← Template para otros
*.tf                      # ← Código de Terraform
README*.md               # ← Documentación
docs/                    # ← Guías
```

---

## 📝 Verificación

### Comprobar que terraform.tfvars NO está en Git:

```bash
# Este comando NO debe mostrar terraform.tfvars
git status

# Verificar .gitignore
cat .gitignore | grep tfvars
# Debe mostrar: *.tfvars
```

### Comprobar que .example SÍ está en Git:

```bash
# Este comando DEBE mostrar terraform.tfvars.example
git ls-files | grep tfvars
```

---

## 🔄 Flujo de Trabajo

### Cuando hagas cambios:

```bash
# 1. Modificas tu archivo real
code terraform.tfvars

# 2. Si añades una nueva variable, actualiza el ejemplo
code terraform.tfvars.example

# 3. Commit solo el ejemplo
git add terraform.tfvars.example
git commit -m "docs: actualizar ejemplo de variables"
git push

# 4. terraform.tfvars nunca se sube (protegido por .gitignore)
```

---

## 📋 Contenido Actual

### terraform.tfvars (TU ARCHIVO - NO EN GIT)

```hcl
region      = "us-east-1"
app_name    = "EB-Dynamo"
env_name    = "eb-dynamo-env"
table_name  = "ContactosCampiclouders"
cors_origin = "*"
instance_type = "t3.micro"

# CONFIGURACIÓN DE MONITOREO
alert_email = ""  # ← CAMBIAR POR TU EMAIL
alarm_5xx_threshold = 10
alarm_latency_threshold = 3.0
alarm_cpu_threshold = 80
alarm_dynamodb_errors_threshold = 5
alarm_app_error_threshold = 20
log_retention_days = 7
```

### terraform.tfvars.example (EN GIT)

```hcl
region      = "us-east-1"
app_name    = "EB-Dynamo"
env_name    = "eb-dynamo-env"
table_name  = "ContactosCampiclouders"
cors_origin = "*"
instance_type = "t3.micro"

# CONFIGURACIÓN DE MONITOREO
alert_email = "tu-email@ejemplo.com"  # ← PLACEHOLDER
alarm_5xx_threshold = 10
alarm_latency_threshold = 3.0
# ... etc
```

---

## ⚡ Quick Start

Para empezar a usar el monitoreo **AHORA**:

```bash
# 1. Abrir tu archivo real
code terraform.tfvars

# 2. Buscar la línea:
alert_email = ""

# 3. Cambiar por tu email:
alert_email = "tu-email-real@ejemplo.com"

# 4. Guardar y aplicar
terraform apply
```

---

## 🎯 Mejores Prácticas

### ✅ DO (Hacer):

1. **Mantén terraform.tfvars actualizado** con tus valores reales
2. **Actualiza terraform.tfvars.example** cuando añadas nuevas variables
3. **Nunca hagas `git add terraform.tfvars`** (Git lo ignorará de todos modos)
4. **Documenta todas las variables** en el .example
5. **Usa valores de ejemplo claros** en el .example (ej: "tu-email@ejemplo.com")

### ❌ DON'T (No hacer):

1. ❌ **NO elimines terraform.tfvars** del .gitignore
2. ❌ **NO pongas datos reales** en terraform.tfvars.example
3. ❌ **NO subas terraform.tfvars** manualmente con `git add -f`
4. ❌ **NO compartas terraform.tfvars** por otros medios (email, slack)
5. ❌ **NO uses el mismo email** en el .example que en el real

---

## 🔍 Troubleshooting

### "Error: No value for required variable"

```bash
# Problema: Terraform no encuentra terraform.tfvars
# Solución: Crear el archivo

cp terraform.tfvars.example terraform.tfvars
code terraform.tfvars
```

### "Git quiere subir terraform.tfvars"

```bash
# Problema: .gitignore no está funcionando
# Solución: Verificar y limpiar cache

# 1. Verificar .gitignore
cat .gitignore | grep tfvars

# 2. Si no está, añadirlo
echo "*.tfvars" >> .gitignore

# 3. Limpiar cache de Git
git rm --cached terraform.tfvars
git add .gitignore
git commit -m "fix: proteger terraform.tfvars"
```

### "Accidentalmente subí terraform.tfvars"

```bash
# ¡EMERGENCIA! Eliminar del historial de Git
# CUIDADO: Esto reescribe el historial

# Opción 1: Si fue el último commit
git reset --soft HEAD~1
git restore --staged terraform.tfvars

# Opción 2: Usar git-filter-repo (recomendado)
git filter-repo --path terraform.tfvars --invert-paths

# Opción 3: BFG Repo-Cleaner
bfg --delete-files terraform.tfvars

# Después de limpiar:
git push --force
```

---

## 📚 Recursos Adicionales

- [Terraform: Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Git: gitignore](https://git-scm.com/docs/gitignore)
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

## 🎓 Resumen

| Archivo | Propósito | En Git? | Contiene datos reales? |
|---------|-----------|---------|------------------------|
| `terraform.tfvars` | Tu configuración | ❌ NO | ✅ SÍ |
| `terraform.tfvars.example` | Template | ✅ SÍ | ❌ NO |

**Regla de oro**: Si tiene `.example` en el nombre, va a Git. Si no, no va.

---

**🔐 Tu archivo terraform.tfvars está protegido y NO se subirá a GitHub gracias al .gitignore.**
