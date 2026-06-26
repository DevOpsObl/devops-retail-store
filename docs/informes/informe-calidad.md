# Informe de calidad y análisis estático — hallazgos, decisiones y remediaciones

**Proyecto:** RetailStore  
**Período analizado:** 21/06/2026 al 23/06/2026  
**Herramientas:** SonarCloud y Semgrep

## 1. Objetivo

El objetivo de este informe es documentar los hallazgos obtenidos mediante análisis estático, las restricciones encontradas durante la configuración de los quality gates y las decisiones adoptadas para evitar que código con problemas críticos sea promovido a los siguientes ambientes.

SonarCloud se utiliza para métricas generales de calidad y mantenibilidad. Semgrep se utiliza como control SAST bloqueante y para analizar código de aplicación, workflows e infraestructura Terraform.

## 2. Resumen ejecutivo

Durante la implementación se identificaron dos grupos de hallazgos:

1. **Limitación de SonarCloud:** el plan gratuito no permitió asignar al proyecto un Quality Gate personalizado.
2. **Hallazgos de Semgrep en Terraform:** se detectaron nueve resultados bloqueantes relacionados con logging, cifrado, TLS, trazabilidad y endurecimiento de servicios AWS.

La respuesta adoptada fue:

- Mantener el Quality Gate integrado `Sonar way`.
- Ejecutar SonarCloud con espera bloqueante mediante `sonar.qualitygate.wait=true`.
- Incorporar Semgrep como gate adicional.
- Clasificar cada hallazgo de Semgrep como:
  - corrección requerida;
  - hardening recomendado;
  - excepción justificada.
- No ocultar findings mediante exclusiones generales sin documentar el riesgo residual.

## 3. Cronología

| Fecha y hora | Evento | Resultado |
|---|---|---|
| 21/06/2026 23:06:59 | Configuración de un Quality Gate personalizado en SonarCloud. | Se definieron límites para duplicación, blockers, critical issues y code smells. |
| 22/06/2026 01:32:06 | Validación de asignación del gate al proyecto. | SonarCloud informó que el plan Free no permite asignar Quality Gates personalizados. |
| 22/06/2026 | Decisión de arquitectura del control. | Se mantuvo `Sonar way` y se incorporó Semgrep como gate SAST bloqueante. |
| 23/06/2026 21:34:56 | Revisión de resultados Semgrep en `feat/Quality-Gate`. | Se clasificaron nueve hallazgos de Terraform y se definió la respuesta para cada uno. |

## 4. SonarCloud

### 4.1. Quality Gate inicialmente propuesto

El gate personalizado contenía, entre otras, las siguientes condiciones sobre código nuevo:

| Métrica | Umbral propuesto |
|---|---:|
| Líneas duplicadas | Máximo 5 % |
| Blocker issues | 0 |
| Critical issues | 0 |
| Code smells | Máximo 5 |

También se evaluó una configuración más estricta basada en cobertura, duplicación, mantenibilidad, confiabilidad, seguridad y revisión de hotspots.

### 4.2. Hallazgo: gate personalizado no asignable

**Fecha de detección:** 22/06/2026 01:32:06

SonarCloud mostró el mensaje de que la asignación de Quality Gates personalizados era una funcionalidad paga y que el plan actual no permitía utilizarla en el proyecto.

**Impacto**

El equipo podía crear o visualizar condiciones personalizadas, pero no aplicarlas efectivamente al proyecto. Documentar ese gate como control real habría sido incorrecto.

**Remediación aplicada**

- Se descartó la afirmación de que el proyecto utiliza un Quality Gate personalizado.
- Se mantuvo el gate integrado **Sonar way**.
- El workflow espera el resultado mediante:

```text
sonar.qualitygate.wait=true
```

- El job falla cuando SonarCloud devuelve un estado distinto de aprobado.
- Semgrep se incorporó como segundo control estático, con comportamiento bloqueante configurable desde el repositorio.

**Resultado**

La limitación comercial quedó documentada y el pipeline conserva un control real, reproducible y verificable sin depender de una funcionalidad no disponible.

## 5. Semgrep

### 5.1. Configuración del gate

Semgrep analiza el repositorio y genera resultados SARIF. El comportamiento bloqueante se basa en hallazgos de severidad `ERROR`.

Configuración relevante:

```bash
semgrep scan \
  --config=auto \
  --severity=ERROR \
  --strict \
  --error \
  --sarif \
  --output=semgrep-results.sarif \
  .
```

El parámetro `--error` provoca que la ejecución termine con código distinto de cero cuando existen hallazgos bloqueantes.

### 5.2. Ejecucion en el pipeline de github actions:

![github actions Semgrep](../assets/informe-calidad/github-actions-calidad.png)

### 5.3. Resumen de hallazgos

El 23/06/2026 a las 21:34:56 se revisaron nueve findings sobre Terraform.

| ID | Hallazgo | Evaluación | Decisión |
|---|---|---|---|
| SEM-01 | ALB sin access logs. | Problema real. | Corregir. |
| SEM-02 | ALB expuesto únicamente por HTTP / TLS no configurado. | Problema real. | Corregir. |
| SEM-03 | RDS sin exportación de logs. | Problema real. | Corregir. |
| SEM-04 | Repositorios ECR con tags mutables. | Problema real. | Corregir. |
| SEM-05 | Lambda sin AWS X-Ray. | Hardening válido. | Corregir. |
| SEM-06 | Subnet pública asignando IP pública automáticamente. | Hallazgo real, aunque no impide el funcionamiento del ALB. | Corregir o justificar según arquitectura. |
| SEM-07 | CloudWatch Log Group sin KMS administrado por el cliente. | No implica ausencia de cifrado; es hardening adicional. | Excepción justificada o CMK. |
| SEM-08 | Segundo CloudWatch Log Group sin KMS administrado por el cliente. | No implica ausencia de cifrado; es hardening adicional. | Excepción justificada o CMK. |
| SEM-09 | Secrets Manager sin KMS administrado por el cliente. | Utiliza cifrado con clave administrada por AWS; CMK es hardening adicional. | Excepción justificada o CMK. |

## 6. Detalle de hallazgos y acciones

### 6.1. SEM-01 — ALB sin access logs

**Riesgo**

Sin access logs se pierde evidencia sobre solicitudes, códigos de respuesta, clientes, latencia y comportamiento del balanceador. Esto dificulta la investigación de incidentes y el análisis de tráfico.

**Remediación definida**

- Crear o reutilizar un bucket S3 destinado a logs del ALB.
- Configurar la policy requerida para que Elastic Load Balancing pueda escribir.
- Agregar el bloque `access_logs` al recurso `aws_lb`.

Ejemplo de cambio esperado:

```hcl
access_logs {
  bucket  = var.access_logs_bucket
  prefix  = var.name_prefix
  enabled = true
}
```

**Estado al cierre del relevamiento**

La corrección fue clasificada como requerida. El informe final debe asociarla al commit y a la ejecución de Semgrep que confirme la desaparición del finding.

---

### 6.2. SEM-02 — ALB con HTTP y política TLS ausente

**Riesgo**

El tráfico entre el cliente y el ALB no está cifrado. Además, al no existir listener HTTPS, no puede definirse una política mínima de TLS.

**Remediación definida**

- Mantener el listener HTTP únicamente para redirigir a HTTPS.
- Crear un listener `HTTPS` en el puerto `443`.
- Asociar un certificado ACM.
- Utilizar una política moderna que admita TLS 1.2 o superior.

Ejemplo:

```hcl
default_action {
  type = "redirect"

  redirect {
    port        = "443"
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
}
```

y:

```hcl
protocol        = "HTTPS"
ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
certificate_arn = var.certificate_arn
```

**Estado al cierre del relevamiento**

Corrección requerida. Su cierre depende de contar con dominio/certificado y de validar nuevamente Semgrep y `terraform plan`.

---

### 6.3. SEM-03 — RDS sin exportación de logs

**Riesgo**

Los logs quedan limitados al servicio de base de datos y no se integran con la plataforma central de observabilidad.

**Remediación definida**

Habilitar exportación a CloudWatch:

```hcl
enabled_cloudwatch_logs_exports = [
  "postgresql",
  "upgrade"
]
```

**Validación requerida**

- `terraform validate`.
- `terraform plan`.
- Confirmación en CloudWatch Logs.
- Nueva ejecución de Semgrep.

---

### 6.4. SEM-04 — ECR con tags mutables

**Riesgo**

Una misma etiqueta puede apuntar a imágenes distintas con el tiempo. Esto reduce la trazabilidad y permite reemplazar un artefacto ya promovido.

**Remediación definida**

Configurar:

```hcl
image_tag_mutability = "IMMUTABLE"
```

La publicación debe utilizar tags únicos, preferentemente el SHA del commit.

**Validación requerida**

Intentar publicar nuevamente un tag existente debe ser rechazado por ECR.

---

### 6.5. SEM-05 — Lambda sin X-Ray

**Riesgo**

No existe trazabilidad distribuida para investigar latencias y fallos internos de la función.

**Remediación definida**

Agregar:

```hcl
tracing_config {
  mode = "Active"
}
```

**Evaluación**

Se considera hardening válido, especialmente si la Lambda participa en la validación de despliegues o en procesamiento de eventos.

---

### 6.6. SEM-06 — asignación automática de IP pública en subnet

**Riesgo**

Los recursos lanzados en la subnet pueden recibir IP pública por defecto, aumentando la superficie de exposición accidental.

**Remediación definida**

Configurar:

```hcl
map_public_ip_on_launch = false
```

El ALB puede seguir siendo público sin que cada recurso asociado reciba una IP pública automática.

**Consideración**

Debe verificarse que ningún componente dependa de esa asignación para administración o salida a Internet.

---

### 6.7. SEM-07 y SEM-08 — CloudWatch Logs sin CMK propia

**Evaluación**

El finding no significa que los logs estén almacenados sin cifrar. CloudWatch Logs cifra los datos en reposo con claves administradas por AWS. Semgrep recomienda una clave administrada por el cliente como endurecimiento adicional.

**Decisión adoptada**

Para el alcance académico pueden documentarse como excepción justificada cuando:

- no existe un requisito contractual de CMK;
- el entorno no maneja datos altamente sensibles;
- se acepta la dependencia de claves administradas por AWS.

La alternativa es definir `kms_key_id` y la policy correspondiente.

**Riesgo residual**

El equipo no controla de forma independiente la rotación, revocación y política de la clave.

---

### 6.8. SEM-09 — Secrets Manager sin CMK propia

**Evaluación**

Secrets Manager cifra los secretos con una clave administrada por AWS cuando no se especifica una CMK. Por lo tanto, el hallazgo representa hardening y control adicional, no un secreto almacenado en texto plano.

**Decisión adoptada**

- Excepción justificada para el alcance del proyecto; o
- creación de una CMK y configuración de `kms_key_id`.

**Riesgo residual**

Menor control sobre separación de funciones, auditoría de uso y revocación específica de la clave.

## 7. Estado de remediación

La evidencia disponible permite distinguir tres estados:

| Estado | Elementos |
|---|---|
| Remediación confirmada | Uso de `Sonar way`, espera bloqueante del Quality Gate e incorporación de Semgrep. |
| Corrección definida y pendiente de evidencia final | Access logs del ALB, HTTPS/TLS, exportación de logs de RDS, tags inmutables de ECR, X-Ray y asignación automática de IP pública. |
| Excepción documentable | Dos findings de CloudWatch Logs sin CMK y Secrets Manager sin CMK propia. |

No debe indicarse que los seis cambios Terraform están cerrados hasta contar con:

1. Diff o commit de implementación.
2. `terraform validate`.
3. `terraform plan`.
4. Ejecución de Semgrep sin esos findings.
5. Captura o artefacto SARIF del workflow.

## 8. Quality gate final

| Control | Condición | Resultado esperado |
|---|---|---|
| SonarCloud | Quality Gate integrado distinto de aprobado. | El job falla. |
| Semgrep | Hallazgo `ERROR`. | El job falla por `--error`. |
| Promoción | Jobs de calidad o seguridad fallidos. | No se publican ni despliegan imágenes. |

Para que el gate sea efectivo, los jobs de publicación y despliegue deben declarar explícitamente los jobs de calidad y seguridad en `needs`.

## 9. Recomendaciones

| Prioridad | Recomendación |
|---|---|
| Alta | Ejecutar Semgrep después de cada corrección y conservar el SARIF como artefacto. |
| Alta | Vincular cada hallazgo con archivo, línea, commit de corrección y resultado de validación. |
| Alta | Verificar que publicación y despliegue dependan de SonarCloud y Semgrep en Dev, Test y Prod. |
| Media | Implementar HTTPS y access logs antes de considerar productivo el ALB. |
| Media | Revisar periódicamente las excepciones de KMS y convertirlas en CMK si cambia la sensibilidad de los datos. |
| Baja | Incorporar ESLint para feedback rápido en los servicios JavaScript/TypeScript. |

## 10. Evidencias utilizadas

| Evidencia | Contenido |
|---|---|
| `2026-06-21_23h06_59.png` | Condiciones configuradas para el Quality Gate personalizado. |
| `2026-06-22_01h32_06.png` | Restricción del plan Free para asignar el gate. |
| `2026-06-23_21h34_56.png` | Clasificación de nueve hallazgos Semgrep. |
| `.github/workflows/reusable-code-quality.yml` | Integración y espera del Quality Gate SonarCloud. |
| `.github/workflows/reusable-security-analysis.yml` | Ejecución bloqueante de Semgrep y generación SARIF. |
| `infra/modules/alb/main.tf` | Configuración del ALB. |
| Módulos Terraform de RDS, ECR, Lambda, red, logging y secretos | Archivos afectados por los findings. |
