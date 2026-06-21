# Testing

Este documento describe la estrategia de testing aplicada al proyecto **DevOps Retail Store**.

La solución busca validar automáticamente el comportamiento de los principales microservicios antes de promover una versión entre los ambientes **Dev**, **Test** y **Prod**.

> Estado del documento: en elaboración.
> Las secciones de resultados, hallazgos, correcciones y evidencias se completarán luego de ejecutar las pruebas sobre el proyecto.

## 1. Objetivo

El objetivo de la estrategia de testing es detectar errores funcionales y problemas de integración antes de desplegar una versión de Retail Store en el siguiente ambiente.

Las validaciones serán ejecutadas automáticamente desde el pipeline de integración continua y funcionarán como controles obligatorios para la promoción de artefactos.

Los objetivos específicos son:

* Validar que los principales microservicios estén disponibles.
* Verificar el funcionamiento de los endpoints críticos.
* Comprobar la integración entre catálogo, carrito, checkout y órdenes.
* Evitar que una versión con pruebas fallidas sea promovida.
* Generar evidencias reproducibles de las validaciones realizadas.

## 2. Alcance

La estrategia contempla pruebas funcionales y de integración sobre los siguientes microservicios:

| Microservicio | Responsabilidad                                      |
| ------------- | ---------------------------------------------------- |
| `ui`          | Interfaz principal de la aplicación.                 |
| `admin`       | Interfaz o servicio de administración.               |
| `catalog`     | Consulta y administración del catálogo de productos. |
| `carts`       | Gestión de carritos y productos seleccionados.       |
| `checkout`    | Procesamiento del flujo de checkout.                 |
| `orders`      | Registro y consulta de órdenes generadas.            |

Las pruebas se ejecutarán mediante solicitudes HTTP hacia los endpoints expuestos por el **Application Load Balancer**.

Las bases PostgreSQL y Redis no serán probadas directamente. Su funcionamiento se validará indirectamente mediante las operaciones de los microservicios que utilizan persistencia.

La primera etapa no contempla pruebas completas de interfaz gráfica ni pruebas de carga de larga duración. Estas podrán incorporarse como mejora posterior.

## 3. Herramientas seleccionadas

### 3.1. Postman

Postman se utilizará para definir las solicitudes, variables, datos y aserciones correspondientes a las pruebas funcionales y de integración.

La colección incluirá los principales flujos de Retail Store y podrá ejecutarse tanto manualmente como desde línea de comandos.

### 3.2. Newman

Newman será utilizado para ejecutar automáticamente la colección de Postman.

Su integración con el pipeline permitirá:

* Ejecutar las pruebas sin intervención manual.
* Bloquear el pipeline cuando una validación falle.
* Generar reportes en consola.
* Exportar resultados.
* Conservar los reportes como evidencia del pipeline.

## 4. Casos de prueba

La colección de Postman se organizará en grupos según el microservicio o flujo validado.

### 4.1. Disponibilidad de servicios

| ID      | Caso                               | Resultado esperado                        | Estado    |
| ------- | ---------------------------------- | ----------------------------------------- | --------- |
| DISP-01 | Consultar la aplicación principal. | La aplicación responde sin errores `5xx`. | Pendiente |
| DISP-02 | Consultar el servicio de catálogo. | El servicio responde correctamente.       | Pendiente |
| DISP-03 | Consultar el servicio de carritos. | El servicio responde correctamente.       | Pendiente |
| DISP-04 | Consultar el servicio de checkout. | El servicio responde correctamente.       | Pendiente |
| DISP-05 | Consultar el servicio de órdenes.  | El servicio responde correctamente.       | Pendiente |

### 4.2. Catálogo

| ID     | Caso                               | Resultado esperado                                               | Estado    |
| ------ | ---------------------------------- | ---------------------------------------------------------------- | --------- |
| CAT-01 | Obtener el listado de productos.   | Se obtiene una respuesta exitosa con una colección de productos. | Pendiente |
| CAT-02 | Obtener un producto existente.     | Se devuelve el producto solicitado.                              | Pendiente |
| CAT-03 | Consultar un producto inexistente. | Se devuelve una respuesta controlada, sin error interno.         | Pendiente |

### 4.3. Carrito

| ID      | Caso                             | Resultado esperado                                      | Estado    |
| ------- | -------------------------------- | ------------------------------------------------------- | --------- |
| CART-01 | Crear o inicializar un carrito.  | Se genera un carrito válido.                            | Pendiente |
| CART-02 | Agregar un producto existente.   | El producto queda asociado al carrito.                  | Pendiente |
| CART-03 | Consultar el carrito.            | Se visualizan los productos agregados.                  | Pendiente |
| CART-04 | Agregar un producto inexistente. | La aplicación rechaza la operación de forma controlada. | Pendiente |

### 4.4. Checkout y órdenes

| ID       | Caso                                                  | Resultado esperado                               | Estado    |
| -------- | ----------------------------------------------------- | ------------------------------------------------ | --------- |
| CHECK-01 | Iniciar checkout con un carrito válido.               | El proceso se inicia correctamente.              | Pendiente |
| CHECK-02 | Ejecutar checkout con un carrito inexistente o vacío. | La aplicación devuelve una respuesta controlada. | Pendiente |
| ORDER-01 | Completar el checkout.                                | Se genera una orden.                             | Pendiente |
| ORDER-02 | Consultar la orden generada.                          | La orden contiene los productos procesados.      | Pendiente |

Los nombres exactos de los endpoints, cuerpos de las solicitudes y códigos HTTP esperados se completarán luego de revisar la implementación real de cada microservicio.

## 5. Flujo de integración probado

El principal escenario de integración validará el siguiente flujo:

```text
Catalog
   ↓
Carts
   ↓
Checkout
   ↓
Orders
```

El flujo realizará los siguientes pasos:

1. Consultar el catálogo de productos.
2. Seleccionar un producto válido.
3. Crear o identificar un carrito.
4. Agregar el producto al carrito.
5. Consultar el carrito y validar su contenido.
6. Iniciar el proceso de checkout.
7. Completar la operación.
8. Obtener el identificador de la orden generada.
9. Consultar la orden.
10. Verificar que la orden contenga la información esperada.

Los identificadores generados durante la ejecución se almacenarán en variables de la colección de Postman.

Ejemplos:

```javascript
pm.collectionVariables.set("productId", productId);
pm.collectionVariables.set("cartId", cartId);
pm.collectionVariables.set("orderId", orderId);
```

Esto permitirá que las solicitudes posteriores utilicen los resultados obtenidos en los pasos anteriores.

## 6. Ejecución local

### 6.1. Requisitos

Para ejecutar las pruebas localmente será necesario contar con:

* Docker.
* Docker Compose.
* Node.js.
* Newman.
* Los microservicios de Retail Store disponibles.

### 6.2. Instalación de Newman

```bash
npm install --save-dev newman
```

### 6.3. Inicio de los servicios

Desde la raíz del repositorio:

```bash
docker compose up -d
```

Antes de ejecutar las pruebas se deberá esperar a que los servicios estén disponibles.

El estado de los contenedores podrá verificarse mediante:

```bash
docker compose ps
```

### 6.4. Ejecución de la colección

```bash
newman run tests/postman/retailstore-integration.postman_collection.json \
  --environment tests/postman/environments/dev.postman_environment.json \
  --reporters cli,junit \
  --reporter-junit-export reports/newman/dev-results.xml
```

El comando devolverá un código de salida distinto de cero cuando una prueba o aserción falle.

### 6.5. Finalización del entorno

```bash
docker compose down
```

## 7. Integración con GitHub Actions

Las pruebas serán incorporadas como una etapa del pipeline de integración continua.

Ejemplo inicial de ejecución:

```yaml
- name: Install Newman
  run: npm install --global newman

- name: Run integration tests
  run: |
    mkdir -p reports/newman

    newman run tests/postman/retailstore-integration.postman_collection.json \
      --environment tests/postman/environments/test.postman_environment.json \
      --reporters cli,junit \
      --reporter-junit-export reports/newman/test-results.xml
```

El reporte generado deberá almacenarse como artefacto del workflow:

```yaml
- name: Upload Newman report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: newman-test-results
    path: reports/newman/
```

El uso de `if: always()` permitirá conservar el reporte incluso cuando las pruebas fallen.

### 7.1. Ejecución por ambiente

| Rama      | Ambiente | Pruebas                                                |
| --------- | -------- | ------------------------------------------------------ |
| `develop` | Dev      | Pruebas funcionales y smoke tests.                     |
| `testing` | Test     | Suite completa de integración.                         |
| `main`    | Prod     | Smoke tests no destructivos posteriores al despliegue. |

Las pruebas de producción evitarán operaciones que generen datos permanentes, salvo que se implemente un mecanismo de limpieza o datos específicos para testing.

## 8. Quality gate de pruebas funcionales

El pipeline será bloqueado cuando ocurra alguna de las siguientes condiciones:

* Falla una prueba considerada crítica.
* Falla alguna aserción de Newman.
* Un endpoint crítico devuelve un código HTTP `5xx`.
* No es posible completar el flujo de catálogo, carrito, checkout y órdenes.
* Una solicitud crítica supera los `2000 ms`.
* Newman finaliza con un código de salida distinto de cero.

El objetivo será obtener:

```text
100 % de pruebas críticas aprobadas
```

## 9. Promoción entre ambientes

El flujo esperado será:

```text
feature/* → develop → testing → main
```

La promoción hacia `testing` requerirá:

* Build correcto.
* Despliegue correcto en Dev.
* Pruebas funcionales aprobadas.

La promoción hacia `main` requerirá:

* Suite de integración aprobada en Test.
* Pull Request aprobado por otro integrante.
* Ausencia de errores bloqueantes conocidos.

Los criterios de análisis estático y calidad de código se documentan por separado en [Calidad de código](./calidad.md).

## 10. Resultados obtenidos

Esta sección se completará luego de ejecutar las pruebas.

| Fecha     | Ambiente | Pruebas ejecutadas | Aprobadas |  Fallidas | Resultado |
| --------- | -------- | -----------------: | --------: | --------: | --------- |
| Pendiente | Dev      |          Pendiente | Pendiente | Pendiente | Pendiente |
| Pendiente | Test     |          Pendiente | Pendiente | Pendiente | Pendiente |
| Pendiente | Prod     |          Pendiente | Pendiente | Pendiente | Pendiente |

## 11. Hallazgos significativos

Esta sección se completará con los problemas reales encontrados durante las pruebas.

Cada hallazgo deberá registrar:

* Identificador.
* Descripción.
* Ambiente donde fue detectado.
* Severidad.
* Evidencia.
* Impacto.
* Estado.

| ID        | Hallazgo                | Severidad | Ambiente  | Estado    |
| --------- | ----------------------- | --------- | --------- | --------- |
| Pendiente | Pendiente de ejecución. | Pendiente | Pendiente | Pendiente |

## 12. Remediaciones aplicadas

Las correcciones realizadas se documentarán indicando el hallazgo asociado y la evidencia de su validación.

| Hallazgo  | Remediación             | Pull Request o commit | Resultado |
| --------- | ----------------------- | --------------------- | --------- |
| Pendiente | Pendiente de ejecución. | Pendiente             | Pendiente |

## 13. Recomendaciones de mejora

Las recomendaciones iniciales son:

* Incorporar pruebas unitarias propias de cada microservicio.
* Incorporar un ambiente de datos exclusivo para testing.
* Automatizar la creación y eliminación de datos de prueba.
* Ampliar las pruebas negativas y de validación.
* Incorporar pruebas de carga con k6.
* Medir latencia percentil 95 y tasa de errores bajo carga.
* Ejecutar pruebas end-to-end de la interfaz.
* Incorporar pruebas de contrato entre microservicios.
* Mantener la colección Postman versionada junto con el código.

Estas recomendaciones podrán ajustarse según los resultados obtenidos.

## 14. Evidencias y capturas

Las evidencias se almacenarán dentro del repositorio.

Estructura propuesta:

```text
docs/
├── testing.md
└── assets/
    └── testing/
        ├── newman-dev.png
        ├── newman-test.png
        ├── github-actions-testing.png
        └── hallazgos/
```

Se deberán incluir como mínimo:

1. Ejecución local de Newman.
2. Resultado de las pruebas en Dev.
3. Resultado de las pruebas en Test.
4. Etapa de testing dentro de GitHub Actions.
5. Ejemplo de pipeline bloqueado ante una prueba fallida.
6. Evidencia de una remediación aplicada.

Las imágenes se agregarán al documento una vez obtenidas:

```markdown
![Resultado de Newman en Dev](assets/testing/newman-dev.png)

![Ejecución de testing en GitHub Actions](assets/testing/github-actions-testing.png)
```

## Estructura de archivos

La estructura propuesta para los recursos de testing es:

```text
tests/
└── postman/
    ├── retailstore-integration.postman_collection.json
    └── environments/
        ├── local.postman_environment.json
        ├── dev.postman_environment.json
        ├── test.postman_environment
        └── prod.postman_environment.json

reports/
└── newman/

docs/
├── testing.md
└── assets/
    └── testing/
```

Los archivos de resultados generados por el pipeline no deberán versionarse, salvo que sean seleccionados expresamente como evidencia final del obligatorio.
