# Infraestructura cloud objetivo

La infraestructura se implementara completamente como codigo utilizando **Terraform** sobre **AWS** en la region `us-east-1`.

La primera version productiva se desplegara sobre **Amazon ECS con Fargate**. Los microservicios `ui`, `admin`, `catalog`, `carts`, `checkout` y `orders` se empaquetaran como imagenes Docker, se publicaran en **Amazon ECR** y luego se ejecutaran como servicios independientes dentro de un cluster ECS. De esta forma, no se crearan ni administraran instancias EC2 para alojar la aplicacion.

Los datos no se alojaran dentro de los contenedores. PostgreSQL se implementara como **Amazon RDS** y Redis como **Amazon ElastiCache**, ambos en subredes privadas. Esto permite que las tareas de ECS Fargate sean reemplazables y que el estado de la aplicacion quede en servicios administrados.

Se desplegara una VPC propia con subredes publicas y privadas distribuidas en dos zonas de disponibilidad. Las subredes publicas alojaran el **Application Load Balancer** y los componentes de entrada. Las subredes privadas alojaran las tareas ECS Fargate, RDS y ElastiCache, sin exposicion publica directa. La salida a internet desde las subredes privadas se realizara mediante **NAT Gateway**.

El codigo Terraform se organizara en modulos reutilizables. Se creara un modulo de red para la VPC, subredes, tablas de ruteo, Internet Gateway y NAT Gateway. Tambien se implementaran modulos separados para seguridad, balanceo, registro de imagenes, orquestacion de contenedores, base de datos, cache, secretos, monitoreo y automatizaciones serverless.

La estructura sera:

```text
infra/
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── tfvars/
│       └── shared.tfvars
├── environment/
│   ├── backend.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend/
│   │   ├── dev.hcl
│   │   ├── test.hcl
│   │   └── prod.hcl
│   └── tfvars/
│       ├── dev.tfvars
│       ├── test.tfvars
│       └── prod.tfvars
└── modules/
    ├── networking/
    ├── security/
    ├── alb/
    ├── ecr/
    ├── ecs/
    ├── database/
    ├── redis/
    ├── secrets/
    ├── monitoring/
    └── lambda/
```

La configuracion usara el mismo codigo Terraform para todos los ambientes. Los parametros se separaran mediante archivos `.tfvars` diferenciados:

```text
dev.tfvars
test.tfvars
prod.tfvars
```

Cada ambiente definira sus propios valores de red, nombres de recursos, tags, parametros de escalado, CPU y memoria de las tareas Fargate, cantidad deseada de replicas por servicio y URIs de imagenes publicadas en ECR. El estado remoto compartira el mismo bucket S3, pero usara un `key` distinto por ambiente, por ejemplo `dev/terraform.tfstate`, `test/terraform.tfstate` y `prod/terraform.tfstate`. El bloqueo de concurrencia del estado se realizara con lockfile nativo del backend S3.

## Networking

El networking se implementara mediante un modulo Terraform dedicado a la capa de red. Este modulo creara la VPC principal, las subredes publicas y privadas, las tablas de ruteo, el Internet Gateway, el NAT Gateway y las asociaciones necesarias entre subredes y rutas.

La VPC se distribuira en dos zonas de disponibilidad de `us-east-1`. En cada zona se definira una subnet publica y una subnet privada. Las subredes publicas alojaran los componentes expuestos a internet, principalmente el **Application Load Balancer** y el **NAT Gateway**. Las subredes privadas alojaran las tareas ECS Fargate de aplicacion y los servicios administrados de persistencia, como **Amazon RDS** y **Amazon ElastiCache**.

El trafico entrante desde internet llegara al **Application Load Balancer**, ubicado en las subredes publicas. El ALB enviara las solicitudes hacia los target groups de los servicios ECS Fargate, sin exponer directamente las tareas a internet.

Las subredes publicas tendran una ruta por defecto hacia el **Internet Gateway**, permitiendo que el ALB reciba trafico publico. Las subredes privadas no tendran ruta directa al Internet Gateway. Para acceder a internet de forma saliente, por ejemplo para descargar imagenes desde ECR o comunicarse con servicios administrados cuando corresponda, las subredes privadas utilizaran un **NAT Gateway** ubicado en una subnet publica.

## Alojamiento de microservicios

Los microservicios se construiran como imagenes Docker y se publicaran en repositorios de **Amazon ECR**. Cada microservicio tendra su propia imagen versionada para permitir despliegues independientes y trazables.

```text
Amazon ECR
├── ui
├── admin
├── catalog
├── carts
├── checkout
└── orders
```

Luego, esas imagenes se ejecutaran en **Amazon ECS con Fargate**. Cada microservicio se definira mediante una task definition y un servicio ECS propio. Fargate administrara la capacidad de computo sin que sea necesario crear, mantener o acceder a instancias EC2.

```text
ECS Fargate cluster
├── service-ui
├── service-admin
├── service-catalog
├── service-carts
├── service-checkout
└── service-orders
```

## Persistencia

La persistencia se separara de los contenedores de aplicacion:

| Componente | Servicio AWS | Uso |
|------------|--------------|-----|
| `catalog`  | Amazon RDS PostgreSQL | Base `catalogdb` para productos y tags |
| `carts`    | Amazon RDS PostgreSQL | Base `cartdb` para items del carrito |
| `orders`   | Amazon RDS PostgreSQL | Base `orders` para ordenes e items |
| `checkout` | Amazon ElastiCache Redis | Estado temporal del proceso de checkout |

RDS y ElastiCache se ubicaran en subredes privadas y solo aceptaran conexiones desde el security group de los servicios ECS Fargate de aplicacion.

## Seguridad de red

Se definiran security groups separados:

| Security group | Reglas principales |
|----------------|--------------------|
| `alb_sg` | Permite HTTP/HTTPS desde internet |
| `ecs_sg` | Permite trafico desde `alb_sg` hacia las tareas ECS Fargate |
| `rds_sg` | Permite PostgreSQL `5432` solo desde `ecs_sg` |
| `redis_sg` | Permite Redis `6379` solo desde `ecs_sg` |
| `lambda_sg` | Permite acceso privado si la Lambda necesita consultar recursos internos |

Las tareas ECS Fargate no tendran IP publica. La operacion se realizara mediante los servicios administrados de AWS, logs en **Amazon CloudWatch Logs** y comandos operativos de ECS cuando sean necesarios, evitando abrir SSH o administrar hosts manualmente.

Como el despliegue se realizara dentro de un laboratorio de AWS, los recursos IAM usaran el rol existente **`LabRole`**. Este rol se asociara a las definiciones de tareas ECS como task execution role y, cuando aplique, como task role para permitir la descarga de imagenes desde ECR, el envio de logs a CloudWatch y el acceso controlado a otros servicios necesarios del laboratorio.

Los outputs de Terraform expondran los datos relevantes de la infraestructura y estaran documentados con descripcion. Se publicara el DNS del balanceador, el ID de la VPC, los IDs de las subredes publicas, los IDs de las subredes privadas y los endpoints necesarios para operacion e integracion.

El estado de Terraform se almacenara en un backend remoto sobre **S3**. El bucket de estado tendra cifrado habilitado, versionado y bloqueo de concurrencia mediante lockfile nativo del backend S3. No se utilizara estado local para la infraestructura objetivo.

Los secretos se gestionaran de forma segura. No se almacenaran credenciales, claves, tokens ni contrasenas en el codigo Terraform ni en archivos `.tfvars` versionados. Los valores sensibles se obtendran desde **AWS Secrets Manager** o **SSM Parameter Store**, y las variables sensibles se declararan con `sensitive = true`.

Se incorporara **AWS Lambda** como servicio serverless para automatizaciones operativas y de seguridad. La funcion Lambda procesara eventos de **CloudWatch** para generar alertas, analizar logs de seguridad y notificar eventos relevantes. Terraform creara la funcion, la asociara al rol **`LabRole`** disponible en el laboratorio cuando corresponda, y definira sus permisos de ejecucion y reglas de invocacion.

La infraestructura resultante quedara definida, versionada y desplegable mediante Terraform, con separacion por ambientes, modulos reutilizables, estado remoto seguro, manejo protegido de secretos y automatizacion serverless integrada.

## Diagrama de componentes

![Diagrama de arquitectura de despliegue](assets/diagrama_arquitectura_despliegue.png)
