# ─── Etapa 1: Construcción (Build) ──────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar archivos de dependencias primero (aprovecha caché de Docker)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar todo el código fuente del proyecto
COPY . .

# Construir la versión Web para producción
RUN flutter build web --release --base-href /agenteTravel/

# ─── Etapa 2: Servidor de producción (Runtime) ──────────────────────────────
FROM nginx:stable-alpine

# Config SPA: rutas desconocidas → index.html (Flutter router)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar los archivos generados por Flutter al subdirectorio del subpath
COPY --from=build /app/build/web /usr/share/nginx/html/agenteTravel

# Exponer el puerto 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
