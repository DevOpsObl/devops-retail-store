# Dependency stage
FROM node:22-alpine AS deps
WORKDIR /app
# COPY . .
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN yarn install

# Build stage
FROM node:22-alpine AS build
WORKDIR /app
# Copiamos lo generado/instalado en la etapa de dependencias.
COPY --from=deps /app ./
# Copiamos el código fuente y archivos necesarios para compilar.
COPY src ./src
COPY nest-cli.json ./
COPY tsconfig.json ./
COPY tsconfig.build.json ./
# Compila la aplicación.
RUN yarn build

# Production stage
FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Copiamos archivos necesarios para instalar/usar dependencias.
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Instalamos dependencias.
RUN yarn install

# Copiamos solo el resultado compilado.
COPY --from=build /app/dist ./dist

# Damos permisos al usuario no-root.
RUN chown -R appuser:appgroup /app

# Ejecutamos como usuario no-root.
USER appuser

EXPOSE 8080
CMD ["node", "dist/main.js"]
