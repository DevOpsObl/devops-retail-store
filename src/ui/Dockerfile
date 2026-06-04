# Dependency stage
FROM node:22-alpine AS deps
WORKDIR /app
# COPY . .
# Copiamos solo package.json y package-lock.json.
COPY package*.json ./
RUN npm install

# Build stage
FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
# Copiamos el resto del código fuente del microservicio.
COPY . .
# Compila TypeScript
RUN npm run build

# Production stage
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

# Creamos un usuario y grupo sin privilegios.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiamos package.json y package-lock.json para instalar solo dependencias productivas.
COPY package*.json ./

# Instala únicamente las dependencias necesarias para ejecutar la app, no agrega dependencias de desarrollo.
RUN npm install --omit=dev

# Copiamos solamente el resultado compilado desde la etapa build.
# No copiamos todo el código fuente ni otros archivos.
COPY --from=build /app/dist ./dist
# Copiamos la carpeta public porque la app admin sirve archivos estáticos desde ahí.
COPY --from=build /app/public ./public

# A partir de acá, el contenedor ejecuta los comandos con el usuario appuser.
USER appuser

EXPOSE 8080
CMD ["node", "dist/app.js"]
