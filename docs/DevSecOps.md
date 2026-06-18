# DevSecOps

Este documento describe la estrategia DevSecOps aplicada en el proyecto, las herramientas seleccionadas, los motivos de su elección y la forma en que fueron integradas dentro del pipeline CI/CD para fortalecer la seguridad del ciclo de desarrollo.

## ¿Qué hace DevSecOps?

Antes de empezar a explicar que hacemos y como, debemos de entender el porqué hacemos esto, y que hace a DevSecOps, DevSecOps.

### Definición

Marco que integra desarrollo, seguridad y operaciones en todo el ciclo de vida del software para reducir vulnerabilidades y riesgos de seguridad.

### Componentes clave

- Integración continua:
  - Los desarrolladores integran código frecuentemente en un repositorio central, donde se compila y prueba automáticamente para detectar errores e incompatibilidades de forma temprana.

- Entrega continua:
  - Automatiza el paso del código desde compilación hasta un entorno de pruebas, ejecutando validaciones funcionales, de integración, APIs y rendimiento para entregar software listo para producción.

- Seguridad DevSecOps:
  - Integra la seguridad en todo el ciclo de vida del desarrollo mediante modelado de amenazas y pruebas de seguridad automatizadas para detectar vulnerabilidades cuanto antes.

## Herramientas

### SAST (Static Application Security Testing)

SAST es una técnica de seguridad que analiza el código fuente, bytecode o binarios sin ejecutar la aplicación. Su objetivo es detectar vulnerabilidades, errores de programación y malas prácticas de seguridad en etapas tempranas del desarrollo.

#### Semgrep

Semgrep es una herramienta de SAST de código abierto que analiza el código mediante reglas predefinidas o personalizadas para identificar vulnerabilidades y problemas de calidad.

#### ¿Por qué se eligió Semgrep?

Los motivos principales de elegir Semgrep como nuestra herramienta SAST son:

- Soporta múltiples lenguajes utilizados en el proyecto:
  - Python
  - TypeScript
  - HTML
  - Dockerfile
  - Go
  - HCL

- Se integra fácilmente en pipelines de GitHub Actions.
- Detecta vulnerabilidades comunes como:
  - Inyecciones de código.
  - Uso inseguro de APIs.
  - Exposición de secretos.
  - Errores de configuración.

- Genera reportes en formatos estándar como SARIF para integrarse con herramientas de análisis de seguridad.

### SCA (Software Composition Analysis)

SCA es una técnica que permite analizar las dependencias y bibliotecas de terceros utilizadas por una aplicación para identificar vulnerabilidades conocidas (CVEs), componentes obsoletos y riesgos de licenciamiento.

#### Trivy

Trivy es una herramienta de seguridad de código abierto que permite analizar dependencias, sistemas de archivos, imágenes de contenedor y configuraciones en busca de vulnerabilidades conocidas.

#### ¿Por qué se eligió Trivy?

Los motivos principales de elegir Trivy como herramienta de SCA son:

- Soporta múltiples ecosistemas de dependencias:
  - npm
  - pip
  - Go Modules
  - Maven
  - NuGet

- Posee una base de datos actualizada de vulnerabilidades conocidas.
- Es rápida y sencilla de integrar en GitHub Actions.
- Permite analizar múltiples microservicios desde una misma ejecución.
- Genera reportes en formatos JSON, SARIF y tablas legibles para auditoría.

### Quality Gate

Un Quality Gate es un conjunto de reglas que determina si una aplicación cumple los requisitos mínimos de seguridad antes de avanzar a la siguiente etapa del pipeline.

#### Trivy

Se utiliza Trivy para evaluar los resultados de los análisis de dependencias e imágenes de contenedor.

#### Criterio definido

El pipeline falla automáticamente cuando se detectan vulnerabilidades de severidad HIGH o CRITICAL.

Este criterio asegura que únicamente se desplieguen artefactos que cumplan con los estándares mínimos de seguridad definidos para el proyecto.

### Escaneo de Imágenes

El escaneo de imágenes permite identificar vulnerabilidades presentes en el sistema operativo base, librerías instaladas y paquetes incluidos dentro de los contenedores.

#### Trivy

Trivy analiza cada imagen Docker generada durante el proceso de integración continua antes de ser publicada en el registro de contenedores.

#### ¿Por qué se eligió Trivy?

- Detecta vulnerabilidades en imágenes base como Alpine, Debian o Ubuntu.
- Identifica paquetes vulnerables instalados dentro del contenedor.
- Permite bloquear la publicación de imágenes con riesgos críticos.
- Facilita la corrección temprana mediante la actualización de imágenes base o dependencias.

### Secret Detection

La detección de secretos busca prevenir la exposición accidental de credenciales, claves de acceso, tokens y cadenas de conexión dentro del repositorio.

#### Gitleaks

Gitleaks es una herramienta de código abierto especializada en detectar secretos expuestos mediante reglas predefinidas y personalizables.

#### ¿Por qué se eligió Gitleaks?

Los motivos principales de elegir Gitleaks son:

- Detecta una amplia variedad de credenciales:
  - API Keys
  - Access Tokens
  - Passwords
  - Connection Strings
  - Claves de proveedores cloud

- Se integra fácilmente en GitHub Actions.
- Permite escanear tanto el código actual como el historial de Git.
- Falla automáticamente el pipeline cuando se detectan secretos expuestos.

#### Política aplicada

Ninguna contraseña, token, API Key o cadena de conexión debe almacenarse directamente en el código fuente o archivos de configuración del repositorio.

Toda información sensible debe gestionarse mediante:

- GitHub Secrets.
- Variables de entorno.

## Documentación de hallazgos

Como pedido en el punto 5.5 de la letra del obligatorio, se reportarán todos los hallazgos, y las medidas tomadas.

| Herramienta | Hallazgo Encontrado        | Ubicación  | Remediación                                                                                                                                                                                                                                                                     |
| ----------- | -------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Trivy       | `path-to-regexp`           | `checkout` | Aunque `@nestjs/platform-express` utiliza la versión `"8.4.2"`, la última versión disponible de `express` continúa dependiendo de `router`, que incorpora `path-to-regexp 8.2.0`, por lo que no fue posible actualizarla directamente sin esperar una corrección del proveedor. |
| Trivy       | `glob`                     | `checkout` | Se actualizó `@nestjs/cli` y fue necesario actualizar también `rimraf` para incorporar una versión corregida de `glob`.                                                                                                                                                         |
| Trivy       | `minimatch`                | `checkout` | Se actualizó `@nestjs/cli`, sin embargo, fue necesario forzar una versión más reciente debido a que `fork-ts-checker-webpack-plugin` dependía de una versión vulnerable de `minimatch`.                                                                                         |
| Trivy       | `picomatch`                | `admin`    | La versión de `picomatch` tuvo que ser forzada a la `"4.0.4"`.                                                                                                                                                                                                                  |
| Trivy       | `go.opentelemetry.io/otel` | `catalog`  | Se actualizó la versión de `go.opentelemetry.io/otel` y de Go ya que el primero depende de una versión mayor de Go.                                                                                                                                                             |
| Trivy       | `google.golang.org/grpc`   | `catalog`  | Se actualizó la versión de `google.golang.org/grpc`, ya que `go.opentelemetry.io/otel` trae una versión con vulnerabilidad.                                                                                                                                                     |
| Trivy       | `github.com/jackc/pgx/v5`  | `orders`   | Se actualizó la versión de `github.com/jackc/pgx/v5`                                                                                                                                                                                                                            |
| Trivy       | `multer`                   | `checkout` | Se forzó la versión `2.2.0` de `multer`.                                                                                                                                                                                                                                        |
| Trivy       | `picomatch`                | `ui`       | Se forzó la versión `4.0.4` de `picomatch` porque, `http-proxy-middleware` no trae la necesaria para evitar vulnerabilidades                                                                                                                                                    |

## Excepciones

### Componente: ui

Pese a haber forzado a `picomatch` a su versión `4.0.4`, Trivy detecta que existe una versión anterior, `4.0.3`.

Por lo que se optó, después de confirmar que el container tiene dentro la versión correcta, ignorar este error, y tenerlo como un fallo de Trivy a la hora de detectar vulnerabilidades.

![Picomatch](assets/picomatch-error-ui.png)

- Se creó el container con `docker build -t ui:test .` desde `..\src\ui`.
- Se realizó el scan de `trivy image --severity HIGH,CRITICAL ui:test`.
- Se corrió el comando `docker run --rm -it ui:test sh -c "npm ls picomatch"`, que ejecuta el `npm ls picomatch` dentro del container, devolviendo que la versión utilizada es la correcta.
