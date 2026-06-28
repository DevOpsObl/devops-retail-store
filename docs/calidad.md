# Calidad de código

Este documento describe la estrategia de análisis de calidad aplicada al proyecto **DevOps Retail Store**.

La calidad de código se validará de forma automática dentro del pipeline de integración continua, como complemento de las pruebas funcionales y de integración documentadas en [Testing](./testing.md).

> Estado del documento: en elaboración.
> Las secciones de resultados, hallazgos, correcciones y evidencias se completarán luego de ejecutar los análisis sobre el proyecto.

## 1. Objetivo

El objetivo de la estrategia de calidad es detectar defectos de código, problemas de mantenibilidad, duplicación y riesgos técnicos antes de promover una versión de Retail Store hacia el siguiente ambiente.

Los objetivos específicos son:

* Detectar errores y problemas de mantenibilidad mediante análisis estático.
* Identificar bugs potenciales y code smells.
* Controlar la duplicación en código nuevo.
* Evitar que una versión con problemas críticos de calidad sea promovida.
* Generar evidencias reproducibles del análisis realizado.

## 2. Alcance

El análisis de calidad se aplicará sobre el código de los microservicios y componentes del proyecto.

## 3. Herramientas seleccionadas

SonarCloud aporta el análisis general con el gate disponible en el plan gratuito con `Sonar way` y  `Semgrep` aporta el umbral configurable; `Newman`, `Trivy` y `Gitleaks` bloquean sus respectivos riesgos.

El análisis permitirá identificar:

* Bugs potenciales.
* Code smells.
* Código duplicado.
* Problemas de mantenibilidad.
* Problemas de confiabilidad.
* Problemas de seguridad detectados durante el análisis estático.

## 4. Integración con GitHub Actions

El análisis de calidad será incorporado como una etapa del pipeline de integración continua.

Ejemplo inicial de ejecución:

```yaml
- name: Run SonarCloud analysis
  run: sonar-scanner -Dsonar.qualitygate.wait=true
```
El uso de `sonar.qualitygate.wait=true` permitirá bloquear el pipeline cuando el quality gate no sea aprobado.

```yaml
      - name: Run Semgrep
        run: |
          semgrep scan \
            --config=auto \
            --severity=ERROR \
            --strict \
            --error \
            --exclude=node_modules \
            --exclude=dist \
            --exclude=build \
            --exclude=coverage \
            --sarif \
            --output=semgrep-results.sarif \
            .
```

## 5. Quality gate de análisis estático

| Control | Herramienta | Criterio bloqueante |
|---|---|---|
| Calidad general | SonarCloud | Quality Gate `Sonar way` aprobado |
| Análisis estático | Semgrep | Cero hallazgos `ERROR` |
| Dependencias | Trivy filesystem | Cero HIGH/CRITICAL corregibles |
| Imágenes | Trivy image | Cero HIGH/CRITICAL no exceptuadas |
| Secretos | Gitleaks | Cero secretos detectados |
| Integración funcional | Newman | Todas las pruebas y aserciones aprobadas |

Una versión no podrá promoverse cuando el quality gate de calidad se encuentre fallando.

## 6. Promoción entre ambientes

El flujo esperado será:

```text
feature/* → develop → testing → main
```

La promoción hacia `testing` requerirá:

* Build correcto.
* Análisis estático aprobado.
* Controles de seguridad aprobados.
* Despliegue correcto en Dev.
* Pruebas funcionales aprobadas.

La promoción hacia `main` requerirá:

* Suite de integración aprobada en Test.
* Quality gates aprobados.
* Pull Request aprobado por otro integrante.
* Ausencia de errores bloqueantes conocidos.

En un ambiente real, el gate de promoción `Test -> Prod` también debería ejecutar un health check contra el ambiente de Test antes de publicar en Producción, por ejemplo validando el endpoint `/health` mediante una variable como `TEST_BASE_URL`. Para esta entrega del obligatorio, ese control queda documentado pero no se ejecuta automáticamente, ya que el ambiente de Test no necesariamente estará levantado durante la evaluación.

## 7. Resultados obtenidos

Esta sección registra los resultados y observaciones obtenidos durante la ejecución de los controles de calidad.

| Métrica                     | Resultado |      Umbral | Cumple    |
| --------------------------- | --------: | ----------: | --------- |
| Issues Blocker nuevos       | Pendiente |           0 | Pendiente |
| Issues Critical nuevos      | Pendiente |           0 | Pendiente |
| Code smells Major nuevos    | Pendiente |    Máximo 5 | Pendiente |
| Duplicación en código nuevo | Pendiente | Menor a 5 % | Pendiente |
| Quality Gate                | Pendiente |    Aprobado | Pendiente |
| Secretos Gitleaks           | Falso positivo `curl-auth-user` documentado | 0 secretos reales | Cumple con excepción |

## 8. Hallazgos significativos

Esta sección se completará con los problemas reales encontrados durante el análisis.

Cada hallazgo deberá registrar:

* Identificador.
* Descripción.
* Ambiente o rama donde fue detectado.
* Severidad.
* Evidencia.
* Impacto.
* Estado.

| ID        | Hallazgo                | Severidad | Ambiente o rama | Estado    |
| --------- | ----------------------- | --------- | --------------- | --------- |
| GIT-001 | Gitleaks reportó `curl-auth-user` en `.github/workflows/reusable-code-quality.yml` por el uso de `curl --user "${SONAR_TOKEN}:"` contra la API de SonarCloud. El valor no está hardcodeado: se inyecta desde GitHub Secrets en tiempo de ejecución. Se agregó `gitleaks:allow` únicamente en esa línea y el scan de secretos queda enfocado en el estado vigente del repositorio para evitar bloquear Test o Prod por el commit histórico ya corregido. | Baja | Testing / Producción | Falso positivo documentado |

## 9. Remediaciones aplicadas

Las correcciones realizadas se documentarán indicando el hallazgo asociado y la evidencia de su validación.

| Hallazgo  | Remediación             | Pull Request o commit | Resultado |
| --------- | ----------------------- | --------------------- | --------- |
| Pendiente | Pendiente de ejecución. | Pendiente             | Pendiente |

Cuando un hallazgo no pueda corregirse dentro del alcance del proyecto, deberá documentarse como excepción justificada.

La excepción deberá incluir:

* Motivo.
* Riesgo aceptado.
* Impacto.
* Medida de mitigación.
* Responsable de la decisión.

## 10. Recomendaciones de mejora

Las recomendaciones iniciales son:

* Generar reportes de cobertura para todos los lenguajes utilizados.
* Incorporar cobertura mínima cuando exista una medición real y reproducible.
* Revisar periódicamente duplicación y code smells.
* Mantener la configuración de SonarCloud versionada junto con el código.
* Ajustar los umbrales del quality gate según los resultados obtenidos.

## 11. Evidencias y capturas

Las evidencias se almacenarán dentro del repositorio.

Estructura propuesta:

```text
docs/
├── calidad.md
└── assets/
    └── calidad/
        ├── sonar-quality-gate.png
        ├── github-actions-quality.png
        └── hallazgos/
```

Se deberán incluir como mínimo:

1. Resultado del análisis de SonarCloud.
2. Quality Gate de SonarCloud.
3. Etapa de calidad dentro de GitHub Actions.
4. Ejemplo de pipeline bloqueado ante un quality gate fallido.
5. Evidencia de una remediación aplicada.

Las imágenes se agregarán al documento una vez obtenidas:

```markdown
![Quality Gate de SonarCloud](assets/calidad/sonar-quality-gate.png)

![Ejecución de calidad en GitHub Actions](assets/calidad/github-actions-quality.png)
```
