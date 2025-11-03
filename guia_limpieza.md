# 🧹 Guía de Limpieza/Destrucción — EB + DynamoDB

Lista consolidada para desmontar el ambiente según el método de despliegue usado: Terraform, AWS CLI, CloudFormation o desde la consola web.

---

## ⚠️ Recomendaciones generales
- Verifica qué creó cada método: si combinaste Terraform con despliegues manuales, puede que `destroy` no elimine todo.
- Revisa S3: elimina artefactos (ZIPs) y buckets usados solo para EB.
- Roles IAM: no borres roles compartidos con otros proyectos. Si dudás, renombra/usa prefijos por proyecto.

---

## 1) Terraform

Ejecuta desde el directorio donde están tus archivos `.tf`:
```bash
terraform destroy
```

Si el rol `aws-elasticbeanstalk-ec2-role` o el Instance Profile ya existían y los gestionaste fuera de Terraform:
- Terraform puede fallar o dejarlos fuera. Elimínalos manualmente solo si fueron creados para este proyecto.

Sobrantes comunes fuera del estado:
- Application Versions de EB (si desplegaste con EB CLI o manual): bórralas desde EB → Application versions.
- Buckets S3 de artefactos (si los creaste tú fuera de Terraform).

---

## 2) AWS CLI

Asumiendo variables (ajústalas si usaste otros nombres):
```bash
export AWS_REGION=us-east-1
export APP_NAME=EB-Dynamo
export ENV_NAME=eb-dynamo-env
export TABLE_NAME=ContactosCampiclouders
export SR_NAME="${APP_NAME}-eb-service-role"
export ROLE_NAME="${APP_NAME}-eb-ec2-role"
export BUCKET_NAME=my-eb-artifacts-$(aws sts get-caller-identity --query Account --output text)-$AWS_REGION
```

Teardown completo por CLI:
```bash
# 1) Terminar Environment y borrar Application (fuerza borrado de env)
aws elasticbeanstalk terminate-environment --environment-name "$ENV_NAME" || true
aws elasticbeanstalk delete-application --application-name "$APP_NAME" --terminate-env-by-force || true

# 2) Borrar tabla DynamoDB (si fue solo de laboratorio)
aws dynamodb delete-table --table-name "$TABLE_NAME" || true

# 3) Roles/Profiles de EB creados para el proyecto
aws iam detach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth || true
aws iam detach-role-policy --role-name "$SR_NAME" --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkService || true
aws iam delete-role --role-name "$SR_NAME" || true

aws iam remove-role-from-instance-profile --role-name "$ROLE_NAME" --instance-profile-name "${ROLE_NAME}-profile" || true
aws iam delete-instance-profile --instance-profile-name "${ROLE_NAME}-profile" || true
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name ddbBasicAccess || true
aws iam delete-role --role-name "$ROLE_NAME" || true

# 4) S3 artefactos (ZIPs) y bucket (si es exclusivo del proyecto)
aws s3 rm s3://$BUCKET_NAME --recursive || true
aws s3api delete-bucket --bucket "$BUCKET_NAME" || true
```

Notas:
- `delete-application` con `--terminate-env-by-force` intenta terminar entornos activos.
- Si el bucket tiene versionado, usa `aws s3api delete-object --bucket ... --key ... --version-id ...` o vacíalo desde la consola.

---

## 3) CloudFormation

Si desplegaste con la plantilla `cloudformation/eb-dynamo.yml`:

Opción CLI:
```bash
aws cloudformation delete-stack --stack-name eb-dynamo-stack
aws cloudformation wait stack-delete-complete --stack-name eb-dynamo-stack
```

Opción consola web (paso a paso):
- Abre CloudFormation → Stacks → selecciona tu stack (ej. `eb-dynamo-stack`).
- Click en “Delete” → confirma.
- Espera a que el estado sea “DELETE_COMPLETE”.

Qué se elimina con el stack:
- EB Environment, Application y ApplicationVersion indicados.
- Roles IAM del servicio EB y de EC2 (si fueron creados por la plantilla).
- Tabla DynamoDB.

Qué puede quedar:
- Artefacto S3 (ZIP) si el bucket no forma parte del stack. Bórralo manualmente si fue solo de laboratorio.

---

## 4) Consola Web (despliegue manual)

Orden sugerido para evitar dependencias:
1. Elastic Beanstalk
   - Entra a EB → Environments → selecciona tu environment → Actions → Terminate.
   - En EB → Applications → selecciona tu app → Application versions → borra las versiones si no las reutilizarás.
   - Luego, borra la Application (si ya no hay environments vinculados).
2. DynamoDB
   - Tables → selecciona `ContactosCampiclouders` → Delete table (si era solo de laboratorio).
3. IAM
   - Instance Profiles → selecciona `APP-eb-ec2-role-profile` → Remove role y Delete.
   - Roles → selecciona `APP-eb-ec2-role` → Policies → quita `ddbBasicAccess` si es inline → Delete role.
   - Roles → selecciona `APP-eb-service-role` → Detach managed policies → Delete role.
4. S3
   - Buckets → abre el bucket de artefactos → Empty (vaciar) → Delete bucket (si es exclusivo del proyecto).

Tips:
- Si EB muestra dependencias, primero elimina el Environment y Application Versions.
- Para buckets con versionado habilitado, usa “Empty bucket” (vaciar) para borrar todas las versiones.

