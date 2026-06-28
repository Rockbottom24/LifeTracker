FROM nginx:1.27-alpine

COPY deployment/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY deployment/nginx/nginx.conf /etc/nginx/nginx.conf
COPY frontend/build/web /usr/share/nginx/html

EXPOSE 80
