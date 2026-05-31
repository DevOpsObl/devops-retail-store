# # Multi-stage build
# # Dependency stage
# FROM node:22-alpine AS deps
# WORKDIR /app
# COPY package*.json ./
# # npm install: Instala dependencias y puede modificar el lock
# # npm ci: Instala exactamente lo que dice package-lock.json por lo que es más reproducible
# RUN npm ci

# # Build stage
# FROM node:22-alpine AS build
# WORKDIR /app
# COPY --from=deps /app/node_modules ./node_modules
# COPY . .
# RUN npm run build
# # Production stage
# FROM node:22-alpine AS runtime
# WORKDIR /app
# ENV NODE_ENV=production
# ENV PORT=8080

# RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# COPY package*.json ./
# RUN npm ci --omit=dev

# COPY --from=build /app/dist ./dist

# USER appuser

# EXPOSE 8080
# CMD ["node", "dist/app.js"]

# Multi-stage build
# La idea es dividir la construcción de la imagen en varias etapas. 
# "Limpiando las anteriores" Así evitamos que la imagen final tenga archivos o dependencias que solo se necesitan para compilar.

# Dependency stage
# =========================
# Esta etapa se encarga únicamente de instalar las dependencias del proyecto.
# "AS deps" le da un nombre a esta etapa para poder reutilizarla más adelante.
FROM node:22-alpine AS deps

# Define /app como directorio de trabajo dentro del contenedor.
WORKDIR /app

# Copiamos solo package.json y package-lock.json.
COPY package*.json ./

# npm install: instala dependencias
RUN npm install

# Build stage
# =========================
# Esta etapa se usa para compilar la aplicación. No será la imagen final, solo genera el resultado de build.
FROM node:22-alpine AS build

# Volvemos a definir el directorio de trabajo porque cada stage es independiente.
WORKDIR /app

# Copiamos las dependencias instaladas en la etapa "deps".
# Esto evita ejecutar npm ci de nuevo en esta etapa.
COPY --from=deps /app/node_modules ./node_modules

# Copiamos el resto del código fuente del microservicio.
COPY . .

# Ejecuta el build definido en package.json.
# En este proyecto genera la carpeta dist, que contiene la app compilada.
RUN npm run build


# Runtime / Production stage
# =========================
# Esta es la etapa final.
# Lo que quede acá es lo que realmente va a formar parte de la imagen productiva.
FROM node:22-alpine AS runtime

# Directorio de trabajo de la app en producción.
WORKDIR /app

# Define el entorno como producción.
ENV NODE_ENV=production

# Puerto interno donde escucha este microservicio.
ENV PORT=8080

# Creamos un usuario y grupo sin privilegios.
# Esto evita ejecutar la aplicación como root dentro del contenedor.
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

# Indica que la app escucha en el puerto 8080..
EXPOSE 8080

# Comando que se ejecuta cuando arranca el contenedor.
# Inicia la aplicación compilada.
CMD ["node", "dist/app.js"]