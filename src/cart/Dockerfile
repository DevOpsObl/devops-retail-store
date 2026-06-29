# Multi-stage build
# Dependency stage
FROM python:3.12-slim-bookworm AS deps

WORKDIR /app

RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Creamos un entorno virtual e instalamos las dependencias dentro de él
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.12-slim-bookworm AS runtime

WORKDIR /app

ENV CART_PERSISTENCE_PROVIDER=in-memory
ENV PORT=8080

# Activamos el entorno virtual en el PATH para este stage.
# Esto hace que 'python' y 'uvicorn' apunten automáticamente al venv.
ENV PATH="/opt/venv/bin:${PATH}"

# Actualizamos los paquetes del sistema y creamos un usuario no-root.
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Creamos un usuario no-root por seguridad.
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copiamos el entorno virtual completo desde la etapa anterior
COPY --from=deps /opt/venv /opt/venv

# Copiamos solo el código de la aplicación
COPY app ./app

# Ajustamos permisos
RUN chown -R appuser:appgroup /app /opt/venv

# Ejecutamos como usuario no-root.
USER appuser

EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
