# Infraestructura Terraform

Esta carpeta implementa la arquitectura definida en `docs/infrastructure.md`:

- Amazon ECR para publicar las imagenes Docker de los microservicios.
- Amazon ECS con Fargate para ejecutar `ui`, `admin`, `catalog`, `cart`, `checkout` y `orders`.
- Application Load Balancer publico.
- VPC con subredes publicas y privadas, Internet Gateway y NAT Gateway.
- Amazon RDS PostgreSQL y Amazon ElastiCache Redis en subredes privadas.
- AWS Secrets Manager para credenciales generadas por Terraform.
- CloudWatch Logs y una Lambda de automatizacion.
- Uso del rol IAM `LabRole` del laboratorio AWS.

## Bootstrap del estado remoto

Los comandos `make` se ejecutan desde la raiz del repositorio `devops-retail-store`.

Crear primero el bucket S3 para el estado remoto. El nombre del bucket esta en `infra/bootstrap/tfvars/shared.tfvars`:

```bash
make bootstrap-init
make bootstrap-apply
```

El bootstrap se ejecuta una vez y crea un backend compartido para todos los ambientes. El bloqueo de concurrencia se realiza con `use_lockfile = true` en el backend S3 de cada ambiente.

## Registry de imagenes

Los repositorios ECR viven en `infra/registry/` y se despliegan antes del runtime. Esto permite publicar imagenes aunque la VPC, ECS, RDS o el ALB todavia no existan.

Inicializar y crear ECR para `dev`:

```bash
make registry-init ENV=dev
make registry-plan ENV=dev
make registry-apply ENV=dev
```

Para `test` o `prod`, cambiar solo `ENV`. Si un ambiente ya tenia ECR creado desde el stack anterior `infra/environment`, primero hay que migrar/importar esos repositorios al estado de `infra/registry` antes de quitar su ownership del estado anterior.

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

Para `test` o `prod`, cambiar solo `ENV`:

```bash
make init ENV=test
make plan ENV=test

make init ENV=prod
make plan ENV=prod
```

Luego de crear ECR con `infra/registry`, publicar las imagenes Docker usando los repositorios del output `ecr_repository_urls`. ECS espera encontrar el tag definido en `image_tag`, por defecto `latest`.

## Nota sobre PostgreSQL

RDS crea una base inicial llamada `orders`. Las aplicaciones quedan configuradas para usar `catalogdb`, `cartdb` y `orders`; `catalogdb` y `cartdb` deben crearse mediante un paso de inicializacion/migracion con acceso privado al RDS.
