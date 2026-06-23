# Containerización y publicación de imágenes

## Objetivo

El objetivo de esta etapa fue optimizar la containerización de los microservicios del proyecto **RetailStore**, aplicando buenas prácticas de Docker y dejando las imágenes listas para ser publicadas en un **container registry**.

Se trabajó sobre los siguientes microservicios:

* `admin`
* `ui`
* `cart`
* `catalog`
* `checkout`
* `orders`

Además, el proyecto utiliza servicios externos mediante imágenes oficiales:

* `postgres:16`
* `redis:7-alpine`

Estas últimas no son imágenes propias del proyecto, sino dependencias externas utilizadas desde el `docker-compose.yml`.

---

## Estado inicial

Inicialmente, los Dockerfile de los microservicios funcionaban correctamente, pero eran simples y no aplicaban algunas buenas prácticas recomendadas para entornos productivos.

Por ejemplo, algunos Dockerfile tenían una estructura similar a:

```dockerfile
FROM node:22
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
EXPOSE 8080
CMD ["node", "dist/app.js"]
```

Este enfoque funciona, pero presenta algunas limitaciones:

* Copia todo el código fuente a la imagen.
* Instala dependencias antes de separar entorno de build y runtime.
* Usa imágenes base más pesadas.
* Ejecuta el proceso como usuario root.
* No aprovecha correctamente la caché de Docker.
* No reduce la imagen final a lo estrictamente necesario.

---

## Buenas prácticas aplicadas

Durante esta etapa se aplicaron las siguientes mejoras:

### Multi-stage build

Se separó la construcción de las imágenes en etapas.

En general, se utilizó el siguiente criterio:

* **Dependency stage:** instala dependencias.
* **Build stage:** compila o prepara la aplicación.
* **Runtime stage:** contiene únicamente lo necesario para ejecutar el servicio.

Esto permite que la imagen final sea más liviana y no incluya herramientas de desarrollo innecesarias.

---

### Imágenes base mínimas

Se reemplazaron imágenes base completas por variantes más livianas cuando fue posible.

Ejemplos:

```dockerfile
FROM node:22-alpine
```

```dockerfile
FROM python:3.12-slim
```

```dockerfile
FROM alpine:3.20
```

En el caso de los microservicios desarrollados en Go, se utilizó la imagen de Go únicamente para compilar y luego se copió el binario resultante a una imagen final basada en Alpine.

---

### Usuario no-root

Se configuraron los contenedores para ejecutar la aplicación con un usuario sin privilegios.

Ejemplo en Node:

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser
```

Ejemplo en Python:

```dockerfile
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

USER appuser
```

Esto evita ejecutar los procesos como `root` dentro del contenedor, reduciendo riesgos de seguridad.

---

### Archivos `.dockerignore`

Se agregaron archivos `.dockerignore` para evitar copiar archivos innecesarios al contexto de build.

Ejemplo para servicios Node:

```dockerignore
node_modules
dist
coverage

.git
.gitignore

.env
.env.*

npm-debug.log

Dockerfile
.dockerignore
README.md
```

Ejemplo para servicios Python:

```dockerignore
__pycache__
*.pyc
*.pyo
*.pyd

.pytest_cache
.coverage
coverage
htmlcov

.venv
venv
env

.env
.env.*

.git
.gitignore

Dockerfile
.dockerignore
README.md
```

Ejemplo para servicios Python:

```dockerignore
.git
.gitignore

Dockerfile
.dockerignore

.env
.env.*
```


Esto ayuda a:

* Reducir el tamaño del contexto de build.
* Evitar copiar archivos sensibles.
* Mejorar la velocidad de construcción.
* Mantener las imágenes más limpias.

---

## Ajustes realizados por microservicio

### Admin

El microservicio `admin` fue optimizado usando multi-stage build.

Se identificó que, además del código compilado en `dist`, el servicio necesita la carpeta `public`, ya que sirve el archivo:

```txt
/app/public/index.html
```

Por ese motivo, en la etapa final se copia explícitamente:

```dockerfile
COPY --from=build /app/dist ./dist
COPY --from=build /app/public ./public
```

También se configuró el contenedor para ejecutar con usuario no-root.

---

### UI

El microservicio `ui` tiene una estructura similar a `admin`.

También requiere:

```txt
public/index.html
```

Por lo tanto, la imagen final copia tanto el código compilado como la carpeta `public`.

```dockerfile
COPY --from=build /app/dist ./dist
COPY --from=build /app/public ./public
```

El servicio levantó correctamente mostrando:

```txt
UI listening on :8080
```

---

### Cart

El microservicio `cart` está desarrollado en Python.

Se partió de un Dockerfile simple:

```dockerfile
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
ENV CART_PERSISTENCE_PROVIDER=in-memory
ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
```

Se ajustó para usar:

* `python:3.12-slim`
* multi-stage build
* instalación de dependencias separada
* usuario no-root
* `.dockerignore`

El comando de arranque se mantuvo alineado con el original:

```dockerfile
CMD ["sh", "-c", "python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
```

Se utilizó `python -m uvicorn` para evitar problemas con el PATH del ejecutable `uvicorn`.

---

### Catalog

El microservicio `catalog` está desarrollado en Go.

Dockerfile original:

```dockerfile
FROM golang:1.24
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o catalog .
EXPOSE 8080
CMD ["./catalog"]
```

Se optimizó usando multi-stage build:

* Etapa `build`: compila el binario usando Go.
* Etapa `runtime`: ejecuta únicamente el binario en una imagen liviana.

Además, se compiló con:

```dockerfile
RUN CGO_ENABLED=0 GOOS=linux go build -o catalog .
```

Esto genera un binario estático compatible con Alpine, evitando errores como:

```txt
exec ./catalog: no such file or directory
```

La imagen final ejecuta:

```dockerfile
CMD ["./catalog"]
```

---

### Checkout

El microservicio `checkout` está desarrollado con Node/Nest y utiliza Yarn.

Dockerfile original:

```dockerfile
FROM node:22
WORKDIR /app
COPY . .
RUN yarn install
RUN yarn build
EXPOSE 8080
CMD ["node", "dist/main.js"]
```

Se ajustó para usar:

* `node:22-alpine`
* multi-stage build
* usuario no-root
* copia controlada de archivos necesarios
* instalación con Yarn

El comando final se mantuvo igual:

```dockerfile
CMD ["node", "dist/main.js"]
```

---

### Orders

El microservicio `orders` fue tratado con el mismo criterio aplicado para `catalog` generando con go el binario, y generando una imagen final reducida y ejecutando el servicio como usuario no-root.

---

## Validación local

Luego de ajustar los Dockerfile y los `.dockerignore`, se ejecutó:

```bash
docker compose up --build
```

Los servicios levantaron correctamente:

```txt
admin
ui
carts
catalog
checkout
orders
db
redis
```

También se verificó que las imágenes locales fueran generadas correctamente:

```bash
docker ps
```

Ejemplo de servicios corriendo:

```txt
devops-retail-store-admin
devops-retail-store-ui
devops-retail-store-carts
devops-retail-store-catalog
devops-retail-store-checkout
devops-retail-store-orders
postgres:16
redis:7-alpine
```

---

# Publicación en Amazon ECR

Docker Hub fue utilizado durante una etapa inicial del proyecto. En la implementación actual, las imágenes de los microservicios se almacenan en **Amazon Elastic Container Registry (ECR)** y su publicación se encuentra automatizada mediante **GitHub Actions**.

Los repositorios ECR se crean de forma declarativa utilizando Terraform, permitiendo disponer de registros separados para los ambientes:

- Desarrollo.
- Testing.
- Producción.

La publicación contempla los siguientes microservicios:

| Microservicio | Contexto de construcción | Repositorio ECR |
| --- | --- | --- |
| Catalog | `src/catalog` | `catalog` |
| Orders | `src/orders` | `orders` |
| Checkout | `src/checkout` | `checkout` |
| UI | `src/ui` | `ui` |
| Admin | `src/admin` | `admin` |
| Cart | `src/cart` | `cart` |

En el entorno local, el servicio de carrito puede aparecer identificado como `carts` dentro de Docker Compose. Para el código fuente y Amazon ECR se utiliza el nombre `cart`.

---

## Creación de los repositorios ECR

La creación de los repositorios se encuentra implementada en el workflow reutilizable:

```
.github/workflows/reusable-registry-bootstrap.yml
```

Este workflow configura las credenciales de AWS, inicializa Terraform y aplica la configuración correspondiente al ambiente.

Los comandos ejecutados son equivalentes a:

```bash
terraform -chdir=infra/registry init \
  -reconfigure \
  -backend-config=backend/${TF_ENV}.hcl

terraform -chdir=infra/registry validate

terraform -chdir=infra/registry plan \
  -var-file=tfvars/${TF_ENV}.tfvars

terraform -chdir=infra/registry apply -auto-approve \
  -var-file=tfvars/${TF_ENV}.tfvars
```

La variable `TF_ENV` determina el ambiente sobre el cual se trabaja:

```
dev
test
prod
```

Cada ambiente utiliza su propio archivo de backend remoto y su correspondiente archivo de variables:

```
infra/registry/backend/dev.hcl
infra/registry/backend/test.hcl
infra/registry/backend/prod.hcl
```

```
infra/registry/tfvars/dev.tfvars
infra/registry/tfvars/test.tfvars
infra/registry/tfvars/prod.tfvars
```

Los prefijos utilizados para organizar los repositorios son:

```
devops-retail-store-dev
devops-retail-store-test
devops-retail-store-prod
```

Por ejemplo, los repositorios del ambiente de desarrollo siguen la siguiente estructura:

```
devops-retail-store-dev/catalog
devops-retail-store-dev/orders
devops-retail-store-dev/checkout
devops-retail-store-dev/ui
devops-retail-store-dev/admin
devops-retail-store-dev/cart
```

---

## Autenticación con Amazon ECR

El pipeline configura las credenciales de AWS utilizando:

```yaml
aws-actions/configure-aws-credentials@v6
```

Luego realiza la autenticación contra Amazon ECR mediante:

```yaml
aws-actions/amazon-ecr-login@v2
```

El comando manual equivalente sería:

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login \
      --username AWS \
      --password-stdin \
      <account_id>.dkr.ecr.us-east-1.amazonaws.com
```

Las credenciales no se almacenan dentro del repositorio. Son proporcionadas al workflow mediante secretos de GitHub Actions.

---

## Construcción y análisis de las imágenes

La construcción de validación se encuentra implementada en:

```
.github/workflows/reusable-build-images.yml
```

El workflow utiliza una estrategia de matriz para construir individualmente las imágenes de los seis microservicios.

Cada imagen temporal se identifica mediante el nombre del servicio y el SHA del commit:

```
retail-<servicio>:<github_sha>
```

Por ejemplo:

```
retail-catalog:8f27c4a...
retail-cart:8f27c4a...
```

Después de construir cada imagen, se ejecuta un análisis de vulnerabilidades mediante **Trivy**:

```yaml
- name: Trivy Image Scan
  uses: aquasecurity/trivy-action@v0.36.0
  with:
    image-ref: "${{ steps.image.outputs.uri }}"
    severity: HIGH,CRITICAL
    exit-code: 1
    trivyignores: ${{ matrix.service.path }}/.trivyignore
```

La configuración establece los siguientes criterios:

- Se reportan vulnerabilidades `HIGH` y `CRITICAL`.
- El job falla cuando Trivy encuentra una vulnerabilidad no exceptuada.
- Cada servicio puede disponer de un archivo `.trivyignore`.
- Las excepciones deben estar justificadas y documentadas.
- Una excepción no implica que la vulnerabilidad haya sido eliminada, sino que fue evaluada y aceptada temporalmente.

### Consideración sobre el artefacto publicado

En la implementación actual, el workflow de validación construye y analiza una imagen local. Posteriormente, el workflow de publicación realiza una nueva construcción utilizando el mismo código y el mismo SHA.

Por lo tanto, actualmente no se reutiliza exactamente el mismo artefacto Docker entre las etapas de análisis y publicación.

Como mejora futura, se podría:

- Exportar la imagen construida como artefacto del pipeline.
- Publicar directamente la imagen previamente analizada.
- Verificar el digest de la imagen.
- Ejecutar un análisis adicional sobre la imagen publicada en ECR.

---

## Publicación de imágenes

La publicación se encuentra implementada en:

```
.github/workflows/reusable-publish-images.yml
```

Para cada microservicio, el pipeline:

1. Determina la URI del repositorio ECR.
2. Construye la imagen.
3. La etiqueta con el SHA del commit.
4. Agrega el tag complementario `latest`.
5. Publica ambos tags en Amazon ECR.

Los comandos ejecutados son equivalentes a:

```bash
repository_uri="${ECR_REGISTRY}/${ECR_REPOSITORY_PREFIX}/${SERVICE}"
sha_image_uri="${repository_uri}:${IMAGE_TAG}"
latest_image_uri="${repository_uri}:latest"

docker build --tag "$sha_image_uri" "$SERVICE_PATH"
docker tag "$sha_image_uri" "$latest_image_uri"

docker push "$sha_image_uri"
docker push "$latest_image_uri"
```

Por ejemplo, para el servicio `catalog` en el ambiente de desarrollo se generan imágenes con la siguiente estructura:

```
<account_id>.dkr.ecr.us-east-1.amazonaws.com/devops-retail-store-dev/catalog:<github_sha>
<account_id>.dkr.ecr.us-east-1.amazonaws.com/devops-retail-store-dev/catalog:latest
```

---

## Parametrización y trazabilidad de los tags

Los workflows utilizan el SHA completo del commit como tag principal:

```yaml
image-tag: ${{ github.sha }}
```

El mismo valor se utiliza durante:

1. La construcción de validación.
2. El análisis de vulnerabilidades.
3. La publicación en Amazon ECR.
4. El despliegue mediante Terraform.

El uso del SHA permite relacionar una imagen con el commit exacto que originó su construcción.

Además, se publica el tag `latest` como referencia complementaria:

```
<repositorio>:<github_sha>
<repositorio>:latest
```

El tag basado en el SHA es utilizado para los despliegues porque permite una mayor trazabilidad y evita depender de un tag mutable como `latest`.

Docker Compose se mantiene como herramienta para la ejecución y validación local. La publicación en ECR y el despliegue en AWS no dependen de los tags configurados en `docker-compose.yml`.

---

## Despliegue en AWS ECS

Después de publicar las imágenes, el pipeline ejecuta el workflow reutilizable:

```
.github/workflows/reusable-deploy.yml
```

Este workflow utiliza Terraform para desplegar la infraestructura y los servicios desde:

```
infra/environment
```

La inicialización utiliza un backend remoto diferente para cada ambiente:

```bash
terraform -chdir=infra/environment init \
  -reconfigure \
  -backend-config=backend/${TF_ENV}.hcl
```

El tag de la imagen se envía explícitamente a Terraform:

```bash
terraform -chdir=infra/environment plan \
  -var-file=tfvars/${TF_ENV}.tfvars \
  -var="image_tag=${IMAGE_TAG}"

terraform -chdir=infra/environment apply -auto-approve \
  -var-file=tfvars/${TF_ENV}.tfvars \
  -var="image_tag=${IMAGE_TAG}"
```

De esta forma, las definiciones de tareas de ECS utilizan las imágenes correspondientes al SHA del commit ejecutado por el pipeline.

Los ambientes de GitHub utilizados para controlar los despliegues son:

| Ambiente | GitHub Environment |
| --- | --- |
| Desarrollo | `Develop` |
| Testing | `Test` |
| Producción | `Prod` |

Al finalizar el despliegue, el pipeline obtiene el nombre DNS del Application Load Balancer y publica las URLs en el resumen de GitHub Actions:

```
UI: http://<alb_dns_name>/
Admin: http://<alb_dns_name>/admin/
```

---

## Estado de las dependencias del pipeline

En el pipeline, la publicación depende de que hayan finalizado correctamente:

- El análisis de calidad.
- El análisis de seguridad.
- La construcción y el escaneo de las imágenes.
- Las pruebas automatizadas.

---

## Decisión sobre Redis y PostgreSQL

Redis y PostgreSQL se mantienen como imágenes oficiales externas:

```yaml
db:
  image: postgres:16
```

```yaml
redis:
  image: redis:7-alpine
```

No se generaron imágenes propias para estos servicios porque no contienen código desarrollado por el equipo.

Estas imágenes funcionan como dependencias necesarias para la ejecución de la solución, principalmente durante el desarrollo y las validaciones locales.

No se publican en los repositorios ECR del proyecto, dado que pueden descargarse directamente desde su registro oficial.

---

## Resultado final

Como resultado de esta etapa:

- Se optimizaron los Dockerfile de los seis microservicios.
- Se aplicaron construcciones multi-stage.
- Se utilizaron imágenes base reducidas cuando fue posible.
- Los procesos se configuraron para ejecutarse mediante usuarios no-root.
- Se incorporaron archivos `.dockerignore`.
- Se validó la ejecución local mediante Docker Compose.
- Las imágenes se construyen automáticamente mediante GitHub Actions.
- Las imágenes de validación son analizadas con Trivy.
- El análisis contempla vulnerabilidades `HIGH` y `CRITICAL`.
- Los repositorios ECR se provisionan mediante Terraform.
- Las imágenes se etiquetan con el SHA del commit y con `latest`.
- El SHA del commit se utiliza para mantener la trazabilidad de los despliegues.
- Las imágenes se publican automáticamente en Amazon ECR.
- Los servicios se despliegan en AWS ECS mediante Terraform.
- Las URLs desplegadas se publican en el resumen del workflow.