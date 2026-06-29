# Lecciones aprendidas

Este documento resume las principales lecciones aprendidas durante el proyecto **DevOps Retail Store**, con foco en los aspectos que funcionaron y, especialmente, en aquellas decisiones que se pudieron haber planificado o ejecutado mejor.

## 1. Planificar antes la arquitectura de despliegue

Una de las lecciones mas importantes fue que la infraestructura y el flujo de publicacion de imagenes deben pensarse juntos desde el inicio.

Durante el proyecto se hizo evidente que ECS necesita imagenes ya publicadas para poder crear o actualizar servicios, pero esas imagenes necesitan repositorios ECR existentes. Por eso fue necesario separar Terraform en tres responsabilidades: `bootstrap`, `registry` y `environment`.

Lo que se pudo haber hecho mejor:

* Definir desde el inicio la separacion entre backend remoto, registry y runtime.
* Documentar antes las dependencias entre ECR, imagenes Docker y servicios ECS.
* Validar con un despliegue minimo temprano antes de completar toda la infraestructura.

## 2. Hacer los gates de promocion mas reales

Los pipelines incluyen gates `Dev -> Test` y `Test -> Prod`, pero actualmente funcionan principalmente como evidencia y consolidacion de controles ya ejecutados.

Para un entorno productivo real, estos gates deberian validar el estado del ambiente anterior antes de promover una version. Por ejemplo, el paso `Test -> Prod` podria ejecutar un health check contra el ALB de Test antes de publicar imagenes o desplegar en Produccion.

Lo que se pudo haber hecho mejor:

* Implementar health checks reales contra los ambientes desplegados.
* Validar endpoints criticos antes de promover a Test o Prod.
* Bloquear promociones si el ambiente anterior no esta disponible o no responde correctamente.

## 3. Probar contra los ambientes reales, no solo contra Docker Compose

La suite de Newman se ejecuta correctamente contra un stack local levantado por Docker Compose dentro del runner de GitHub Actions. Esto permitio detectar errores funcionales y regresiones de integracion.

Sin embargo, las pruebas no se ejecutan todavia contra los ALB de `dev`, `test` o `prod`. Esto deja fuera posibles problemas propios del despliegue cloud: reglas del balanceador, variables de entorno, conectividad privada, permisos, secretos o diferencias entre imagen local e imagen publicada.

Lo que se pudo haber hecho mejor:

* Crear ambientes Postman especificos para `dev`, `test` y `prod`.
* Ejecutar pruebas smoke contra el ALB despues de cada despliegue.
* Separar pruebas destructivas de pruebas seguras para poder validar Produccion sin afectar datos.

## 4. Mantener la estrategia Git simple y estricta

La adaptacion simplificada de Gitflow ayudo a ordenar el trabajo: `feature/* -> develop -> testing -> main`.

La mayor leccion fue que la estrategia de ramas funciona mejor cuando esta directamente alineada con los pipelines. Cada rama principal debe tener un proposito claro y un ambiente asociado.

## 5. Valorar la cultura DevOps en la practica

Durante el proyecto pudimos ver de primera mano lo importante y util que es la cultura DevOps para entregar productos de calidad. La combinacion de colaboracion, automatizacion, integracion continua, seguridad, testing, infraestructura como codigo y observabilidad hizo que el proceso de desarrollo y despliegue fuera mas ordenado, repetible y confiable.

Tambien quedo claro que DevOps no se trata solo de herramientas. Las herramientas ayudan, pero el mayor valor aparece cuando el equipo trabaja con una mentalidad de mejora continua, responsabilidad compartida y deteccion temprana de problemas.

## Conclusion

Como conclusion, este proyecto mostro que aplicar una cultura DevOps facilita la construccion, validacion y entrega de software. Automatizar los controles, documentar decisiones, promover cambios entre ambientes y observar el estado de la aplicacion permite reducir errores manuales y mejorar la calidad final del producto.

Aunque hay aspectos que podrian fortalecerse en una siguiente iteracion, especialmente gates reales y pruebas contra ambientes desplegados, la experiencia confirmo que DevOps aporta una base muy valiosa para desarrollar y desplegar con mayor confianza.
