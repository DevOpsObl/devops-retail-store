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

## Publicación en Docker Hub

Se utilizó Docker Hub como container registry.

Usuario utilizado:

```txt
darrioladev1
```

Se publicaron las siguientes imágenes propias del proyecto:

| Microservicio | Imagen                                             |
| ------------- | -------------------------------------------------- |
| admin         | `darrioladev1/devops-retail-store-admin:v1.0.0`    |
| carts         | `darrioladev1/devops-retail-store-carts:v1.0.0`    |
| catalog       | `darrioladev1/devops-retail-store-catalog:v1.0.0`  |
| checkout      | `darrioladev1/devops-retail-store-checkout:v1.0.0` |
| orders        | `darrioladev1/devops-retail-store-orders:v1.0.0`   |
| ui            | `darrioladev1/devops-retail-store-ui:v1.0.0`       |

Las imágenes `postgres:16` y `redis:7-alpine` no fueron publicadas por el equipo porque son imágenes oficiales externas utilizadas como dependencias del proyecto.

---
## TODO

## EDITAR ESTO CON LOS COMANDOS DE ECR

## Comandos utilizados para publicar imágenes

Primero se inició sesión en Docker Hub:

```bash
docker login
```

Luego se construyeron las imágenes:

```bash
docker compose build
```

Se etiquetaron las imágenes locales:

```bash
docker tag devops-retail-store-admin darrioladev1/devops-retail-store-admin:v1.0.0
docker tag devops-retail-store-carts darrioladev1/devops-retail-store-carts:v1.0.0
docker tag devops-retail-store-catalog darrioladev1/devops-retail-store-catalog:v1.0.0
docker tag devops-retail-store-checkout darrioladev1/devops-retail-store-checkout:v1.0.0
docker tag devops-retail-store-orders darrioladev1/devops-retail-store-orders:v1.0.0
docker tag devops-retail-store-ui darrioladev1/devops-retail-store-ui:v1.0.0
```

Finalmente, se publicaron en Docker Hub:

```bash
docker push darrioladev1/devops-retail-store-admin:v1.0.0
docker push darrioladev1/devops-retail-store-carts:v1.0.0
docker push darrioladev1/devops-retail-store-catalog:v1.0.0
docker push darrioladev1/devops-retail-store-checkout:v1.0.0
docker push darrioladev1/devops-retail-store-orders:v1.0.0
docker push darrioladev1/devops-retail-store-ui:v1.0.0
```

---

## Parametrización del tag de imágenes

Para evitar dejar la versión hardcodeada en el `docker-compose.yml`, se propone utilizar una variable de entorno:

```yaml
image: darrioladev1/devops-retail-store-admin:${IMAGE_TAG:-latest}
```

Ejemplo aplicado a los servicios:

```yaml
admin:
  image: darrioladev1/devops-retail-store-admin:${IMAGE_TAG:-latest}
  build:
    context: ./src/admin

ui:
  image: darrioladev1/devops-retail-store-ui:${IMAGE_TAG:-latest}
  build:
    context: ./src/ui

carts:
  image: darrioladev1/devops-retail-store-carts:${IMAGE_TAG:-latest}
  build:
    context: ./src/cart

catalog:
  image: darrioladev1/devops-retail-store-catalog:${IMAGE_TAG:-latest}
  build:
    context: ./src/catalog

checkout:
  image: darrioladev1/devops-retail-store-checkout:${IMAGE_TAG:-latest}
  build:
    context: ./src/checkout

orders:
  image: darrioladev1/devops-retail-store-orders:${IMAGE_TAG:-latest}
  build:
    context: ./src/orders
```

De esta forma, para publicar una versión específica desde PowerShell se puede ejecutar:

```powershell
$env:IMAGE_TAG="v1.0.0"
docker compose build
docker compose push
```

Si no se define `IMAGE_TAG`, Docker Compose utilizará `latest`.

---

## Decisión sobre Redis y PostgreSQL

Redis y PostgreSQL se mantienen como imágenes externas oficiales:

```yaml
db:
  image: postgres:16
```

```yaml
redis:
  image: redis:7-alpine
```

No se generaron imágenes propias para estos servicios porque no contienen código desarrollado por el equipo. Son dependencias externas necesarias para ejecutar la solución localmente.

---

## Resultado final

Como resultado de esta etapa:

* Se optimizaron los Dockerfile de los microservicios.
* Se aplicó multi-stage build.
* Se usaron imágenes base mínimas.
* Se configuró usuario no-root.
* Se agregaron archivos `.dockerignore`.
* Se validó la ejecución local con Docker Compose.
* Se publicaron las imágenes propias en Docker Hub.
* Se dejó preparado el proyecto para integrar la publicación de imágenes en un pipeline de CI/CD.

---

## Evidencias sugeridas

Para la entrega se recomienda incluir capturas de:

* Docker Desktop con los contenedores corriendo.
* Docker Hub mostrando las imágenes publicadas.
* Terminal con `docker compose up --build` exitoso.
* Terminal con `docker push` exitoso.
* Pull Request donde se incorporan los Dockerfile optimizados.
* Issue/card del tablero marcada como finalizada.
