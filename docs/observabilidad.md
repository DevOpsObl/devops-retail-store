# Observabilidad

## CloudWatch

Por su integración nativa con los servicios de AWS, y porque no requiere infraestructura adicional, se optó por usar CloudWatch.

Esta herramienta recibe información directamente de los servicios de AWS, ya sea ECS, EC2, ALB, etc.

También nos permite crear **Dashboards**, **alarmas** y **automatizaciones**

## Métricas

Como dictado en la letra del obligatorio, se eligió una de las siguientes opciones:

- Recolectar métricas de infraestructura (CPU, memoria, red).
- Recolectar métricas de aplicación (latencia, tasa de errores, throughput).

Se decidió recolectar las métricas de **infraestructura**, para tener un mayor control del consumo que nos puede generar tener estos servicios en conjunto levantados.

## Logs

Los logs de todos los servicios serán centralizados en una única tabla, la cual va a permitir _filtrar_ y _buscar_ los mismos.

## Dashboard

Se creará un Dashboard en CloudWatch para centralizar la visualización del estado de la infraestructura.

El dashboard incluye:

- Utilización de CPU de los contenedores ECS.
- Utilización de memoria de los contenedores ECS.
- Tráfico de red entrante y saliente.
- Estado de salud del Load Balancer.

Esto permite detectar rápidamente problemas de rendimiento o disponibilidad de los servicios desplegados.

## Alertas

### Alerta de uso elevado de CPU

- **Métrica:** CPUUtilization

- **Condición de disparo:**
  CPU promedio superior al 80% durante 5 minutos consecutivos.

- **Objetivo:**
  Detectar sobrecarga de los contenedores antes de que afecte el rendimiento de la aplicación.

### Alerta de uso elevado de memoria

- **Métrica:** MemoryUtilization

- **Condición de disparo:**
  Uso de memoria superior al 85% durante 5 minutos consecutivos.

- **Objetivo:**
  Detectar posibles fugas de memoria o saturación de recursos.

### Alerta de errores en la aplicación

- **Métrica:** Cantidad de eventos ERROR en CloudWatch Logs.

- **Condición de disparo:**
  Más de 10 errores registrados en un período de 5 minutos.

- **Objetivo:**
  Detectar fallos de aplicación que puedan afectar la disponibilidad del sistema.
