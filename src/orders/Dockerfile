# Build stage
FROM golang:1.25 AS build
WORKDIR /app
# Copiamos primero go.mod y go.sum para descargar dependencias. (Estilo node_modules)
COPY go.mod go.sum ./
# Descarga las dependencias del proyecto.
RUN go mod download
# Copiamos el resto del código fuente.
COPY . .
# Compila la aplicación y genera el binario "orders".
# CGO_ENABLED=0 genera un binario estático, más compatible con Alpine.
# GOOS=linux asegura que el binario sea para Linux.
RUN CGO_ENABLED=0 GOOS=linux go build -o orders

# Production stage
# No se usa una imagen de go ya que el binario esta compilado y listo para ejecutarse, no necesitamos el entorno de desarrollo de go.
FROM alpine:3.20 AS runtime
WORKDIR /app

# Creamos un usuario no-root por seguridad.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiamos solamente el binario compilado desde la etapa build.
COPY --from=build /app/orders ./orders

# Ejecutamos como usuario no-root.
USER appuser

EXPOSE 8080
CMD ["./orders"]
