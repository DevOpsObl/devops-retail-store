# Infraestructura Terraform

Esta carpeta implementa la arquitectura definida en `docs/infrastructure.md`:

- Amazon ECR para publicar las imagenes Docker de los microservicios.
- Amazon ECS con Fargate para ejecutar `ui`, `admin`, `catalog`, `cart`, `checkout` y `orders`.
- Application Load Balancer publico.
- VPC con subredes publicas y privadas, Internet Gateway y NAT Gateway.
- Amazon RDS PostgreSQL y Amazon ElastiCache Redis en subredes privadas.
- AWS Secrets Manager para credenciales generadas por Terraform.
- CloudWatch Logs y una Lambda que actua como guardia de despliegues ECS.
- Uso del rol IAM `LabRole` del laboratorio AWS.

## Bootstrap del estado remoto

Los comandos `make` se ejecutan desde la raiz del repositorio `devops-retail-store`.

Crear primero el bucket S3 para el estado remoto. El nombre del bucket esta en `infra/bootstrap/tfvars/shared.tfvars`:

```bash
make bootstrap-init
make bootstrap-apply
```

El bootstrap se ejecuta una vez y crea un backend compartido para todos los ambientes. El bloqueo de concurrencia se realiza con `use_lockfile = true` en el backend S3 de cada ambiente.

Para destruir el backend localmente, primero vaciar el bucket de estado remoto y luego ejecutar el destroy:

```bash
make bootstrap-empty-state-bucket CONFIRM_STATE_BUCKET_EMPTY=yes
make bootstrap-destroy
```

Estos comandos son de uso manual y no forman parte de los pipelines. Antes de destruir el backend remoto, todos los estados de registry y runtime deben haber sido eliminados o migrados.

El paso `bootstrap-empty-state-bucket` elimina versiones de objetos y delete markers del bucket S3. Es necesario porque el bucket tiene versionado habilitado y AWS no permite eliminar un bucket con objetos versionados, aunque en la consola se vean solo carpetas como `dev/`, `test/`, `prod/` o `registry/`.

## Registry de imagenes

Los repositorios ECR viven en `infra/registry/` y se despliegan antes del runtime. Esto permite publicar imagenes aunque la VPC, ECS, RDS o el ALB todavia no existan.

Inicializar y crear ECR para `dev`:

```bash
make registry-init ENV=dev
make registry-plan ENV=dev
make registry-apply ENV=dev
```

Para `test` o `prod`, cambiar solo `ENV`. Si un ambiente ya tenia ECR creado desde el stack anterior `infra/environment`, primero hay que migrar/importar esos repositorios al estado de `infra/registry` antes de quitar su ownership del estado anterior.

Para destruir los repositorios ECR de un ambiente localmente:

```bash
make registry-destroy ENV=dev
```

Este comando es de uso manual y no forma parte de los pipelines.

## Ambientes

El codigo Terraform de la infraestructura runtime vive en `infra/environment/` y es el mismo para todos los ambientes. Los parametros cambian mediante archivos `.tfvars`:

```text
infra/environment/tfvars/
├── dev.tfvars
├── test.tfvars
└── prod.tfvars
```

Cada ambiente tiene tambien un archivo de backend con un `key` distinto dentro del mismo bucket S3:

```text
infra/environment/backend/
├── dev.hcl
├── test.hcl
└── prod.hcl
```

Inicializar y desplegar `dev`:

```bash
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

Por defecto `make plan` y `make apply` despliegan el tag `latest`. Para desplegar una imagen especifica, pasar `IMAGE_TAG`:

```bash
make plan ENV=dev IMAGE_TAG=<sha-publicado>
make apply ENV=dev IMAGE_TAG=<sha-publicado>
```

Para `test` o `prod`, cambiar solo `ENV`:

```bash
make init ENV=test
make plan ENV=test

make init ENV=prod
make plan ENV=prod
```

Luego de crear ECR con `infra/registry`, publicar las imagenes Docker usando los repositorios del output `ecr_repository_urls`. El pipeline publica cada imagen con el SHA del commit y tambien con `latest`; ECS despliega el tag definido en `image_tag`, por defecto `latest`.

Para destruir el runtime de un ambiente localmente:

```bash
make destroy ENV=dev
```

Este comando elimina la infraestructura runtime del ambiente seleccionado, pero no elimina los repositorios ECR del stack `infra/registry` ni el backend remoto del stack `infra/bootstrap`. Para una limpieza completa local, el orden recomendado es:

```bash
make destroy ENV=dev
make registry-destroy ENV=dev
make bootstrap-destroy
```

Los comandos de destruccion no son usados por los pipelines y requieren confirmacion interactiva, salvo que se pase `AUTO_APPROVE=-auto-approve`.

## Password del panel admin

El servicio `admin` recibe `ADMIN_USERNAME`, `ADMIN_PASSWORD` y `ADMIN_JWT_SECRET` desde AWS Secrets Manager. Por defecto, Terraform genera una password aleatoria para `ADMIN_PASSWORD`.

Para fijar la password desde GitHub Actions sin guardarla en el repositorio, crear un secret de Actions llamado `ADMIN_PASSWORD` en el repositorio o environment correspondiente. El workflow de deploy lo exporta como `TF_VAR_admin_password`, y Terraform lo guarda en Secrets Manager para que ECS lo inyecte en el contenedor.

Si `ADMIN_PASSWORD` no esta definido o llega vacio, Terraform mantiene el comportamiento seguro y genera una password aleatoria.

Para ejecuciones manuales fuera de GitHub Actions se puede pasar el valor con una variable de entorno:

```bash
TF_VAR_admin_password='admin' make apply ENV=dev
```

## Guardia de despliegue ECS

Cada servicio ECS ejecuta la Lambda `deployment-validator` en `POST_SCALE_UP`. La funcion identifica la task definition de la revision objetivo, consulta solamente sus tasks `RUNNING` y prueba sus IP privadas. No usa el endpoint compartido del ALB, porque durante un deployment ese endpoint podria responder desde la revision anterior.

Se realizan tres intentos separados por 30 segundos. Al agotarlos, la Lambda publica el detalle en SNS y devuelve `FAILED`; ECS revierte a la ultima revision exitosa.

El rol de ejecucion `LabRole` necesita permisos para logs de Lambda, networking VPC, `ecs:DescribeServiceRevisions`, `ecs:ListTasks`, `ecs:DescribeTasks` y `sns:Publish`. El ambiente reutiliza `LabRole` como rol del hook y concede `lambda:InvokeFunction` exclusivamente sobre la funcion mediante su policy basada en recursos, evitando crear o modificar recursos IAM en el laboratorio.

La suscripcion por email de SNS debe confirmarse desde el correo configurado en `alerta_email`. El codigo, contrato del evento y comandos de verificacion estan documentados en `infra/modules/lambda/README.md`.

## Nota sobre PostgreSQL

RDS crea una base inicial llamada `orders`. Las aplicaciones quedan configuradas para usar `catalogdb`, `cartdb` y `orders`; `catalogdb` y `cartdb` se crean automaticamente durante el despliegue mediante una task one-shot de ECS llamada `db-init`, que corre dentro de las subredes privadas con acceso al RDS.
