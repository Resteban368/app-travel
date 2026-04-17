# Usa el build/web ya compilado localmente con: flutter build web --release --base-href /agenteTravel/
FROM nginx:stable-alpine

# Config SPA: rutas desconocidas → index.html (Flutter router)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar los archivos ya construidos por Flutter
COPY build/web /usr/share/nginx/html/agenteTravel

# Exponer el puerto 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
