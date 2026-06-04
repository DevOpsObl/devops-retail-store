# Infraestructura cloud objetivo

La infraestructura se implementara completamente como codigo utilizando **Terraform** sobre **AWS** en la region `us-east-1`.

La primera version productiva se desplegara sobre **EC2 privadas administradas por un Auto Scaling Group**. Cada instancia EC2 ejecutara la aplicacion completa como un conjunto de contenedores Docker: `ui`, `admin`, `catalog`, `carts`, `checkout` y `orders`. De esta forma, los microservicios estaran empaquetados y aislados como contenedores, pero se alojaran juntos en cada instancia del grupo de escalado.

Los datos no se alojaran dentro de las instancias EC2. PostgreSQL se implementara como **Amazon RDS** y Redis como **Amazon ElastiCache**, ambos en subredes privadas. Esto permite que las instancias EC2 sean reemplazables y que el estado de la aplicacion quede en servicios administrados.

Se desplegara una VPC propia con subredes publicas y privadas distribuidas en dos zonas de disponibilidad. Las subredes publicas alojaran el **Application Load Balancer** y los componentes de entrada. Las subredes privadas alojaran las instancias EC2, RDS y ElastiCache, sin exposicion publica directa. La salida a internet desde las subredes privadas se realizara mediante **NAT Gateway**.

El codigo Terraform se organizara en modulos reutilizables. Se creara un modulo de red para la VPC, subredes, tablas de ruteo, Internet Gateway y NAT Gateway. Tambien se implementaran modulos separados para seguridad, balanceo, computo, base de datos, cache, secretos, monitoreo y automatizaciones serverless.

La estructura sera:

```text
infra/
├── bootstrap/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   ├── test/
│   └── prod/
└── modules/
    ├── networking/
    ├── security/
    ├── alb/
    ├── compute/
    ├── database/
    ├── redis/
    ├── secrets/
    ├── monitoring/
    └── lambda/
```

La configuracion se parametrizara por ambiente mediante archivos `.tfvars` diferenciados:

```text
dev.tfvars
test.tfvars
prod.tfvars
```

Cada ambiente definira sus propios valores de red, cantidad de instancias, tipo de instancia, AMI, nombres de recursos, tags y parametros de escalado.

## Networking

El networking se implementara mediante un modulo Terraform dedicado a la capa de red. Este modulo creara la VPC principal, las subredes publicas y privadas, las tablas de ruteo, el Internet Gateway, el NAT Gateway y las asociaciones necesarias entre subredes y rutas.

La VPC se distribuira en dos zonas de disponibilidad de `us-east-1`. En cada zona se definira una subnet publica y una subnet privada. Las subredes publicas alojaran los componentes expuestos a internet, principalmente el **Application Load Balancer** y el **NAT Gateway**. Las subredes privadas alojaran las instancias EC2 de aplicacion y los servicios administrados de persistencia, como **Amazon RDS** y **Amazon ElastiCache**.

El trafico entrante desde internet llegara al **Application Load Balancer**, ubicado en las subredes publicas. El ALB enviara las solicitudes hacia el target group de las instancias EC2 privadas, sin exponer directamente las instancias a internet.

Las subredes publicas tendran una ruta por defecto hacia el **Internet Gateway**, permitiendo que el ALB reciba trafico publico. Las subredes privadas no tendran ruta directa al Internet Gateway. Para acceder a internet de forma saliente, por ejemplo para descargar imagenes o actualizaciones, las subredes privadas utilizaran un **NAT Gateway** ubicado en una subnet publica.

## Alojamiento de microservicios

Los microservicios se alojaran juntos en las instancias EC2 privadas del Auto Scaling Group. Cada instancia tendra Docker instalado y ejecutara los contenedores de la aplicacion mediante Docker Compose.

```text
EC2 privada
├── ui
├── admin
├── catalog
├── carts
├── checkout
└── orders
```

## Persistencia

La persistencia se separara de las instancias de aplicacion:

| Componente | Servicio AWS | Uso |
|------------|--------------|-----|
| `catalog`  | Amazon RDS PostgreSQL | Base `catalogdb` para productos y tags |
| `carts`    | Amazon RDS PostgreSQL | Base `cartdb` para items del carrito |
| `orders`   | Amazon RDS PostgreSQL | Base `orders` para ordenes e items |
| `checkout` | Amazon ElastiCache Redis | Estado temporal del proceso de checkout |

RDS y ElastiCache se ubicaran en subredes privadas y solo aceptaran conexiones desde el security group de las EC2 de aplicacion.

## Seguridad de red

Se definiran security groups separados:

| Security group | Reglas principales |
|----------------|--------------------|
| `alb_sg` | Permite HTTP/HTTPS desde internet |
| `app_sg` | Permite trafico desde `alb_sg` hacia las EC2 |
| `rds_sg` | Permite PostgreSQL `5432` solo desde `app_sg` |
| `redis_sg` | Permite Redis `6379` solo desde `app_sg` |
| `lambda_sg` | Permite acceso privado si la Lambda necesita consultar recursos internos |

Las instancias EC2 no tendran IP publica. La administracion se realizara mediante **AWS Systems Manager Session Manager**, evitando abrir SSH a internet.

Los outputs de Terraform expondran los datos relevantes de la infraestructura y estaran documentados con descripcion. Se publicara el DNS del balanceador, el ID de la VPC, los IDs de las subredes publicas, los IDs de las subredes privadas y los endpoints necesarios para operacion e integracion.

El estado de Terraform se almacenara en un backend remoto sobre **S3**. El bucket de estado tendra cifrado habilitado, versionado y bloqueo de concurrencia mediante **DynamoDB**. No se utilizara estado local para la infraestructura objetivo.

Los secretos se gestionaran de forma segura. No se almacenaran credenciales, claves, tokens ni contrasenas en el codigo Terraform ni en archivos `.tfvars` versionados. Los valores sensibles se obtendran desde **AWS Secrets Manager** o **SSM Parameter Store**, y las variables sensibles se declararan con `sensitive = true`.

Se incorporara **AWS Lambda** como servicio serverless para automatizaciones operativas y de seguridad. La funcion Lambda procesara eventos de **CloudWatch** para generar alertas, analizar logs de seguridad y notificar eventos relevantes. Terraform creara la funcion, su rol IAM de minimos privilegios, sus permisos de ejecucion y las reglas de invocacion correspondientes.

La infraestructura resultante quedara definida, versionada y desplegable mediante Terraform, con separacion por ambientes, modulos reutilizables, estado remoto seguro, manejo protegido de secretos y automatizacion serverless integrada.

## Diagrama de componentes

![Diagrama de arquitectura de despliegue](assets/diagrama_arquitectura_despliegue.png)
