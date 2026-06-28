FROM ghcr.io/cirruslabs/flutter:stable AS flutter_build
WORKDIR /app

ARG API_BASE_URL=/api/v1
ENV API_BASE_URL=${API_BASE_URL}

COPY frontend/pubspec.yaml frontend/pubspec.lock* ./frontend/
WORKDIR /app/frontend
RUN flutter pub get

COPY frontend/ /app/frontend/
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine
RUN apk add --no-cache bash

COPY deployment/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY deployment/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=flutter_build /app/frontend/build/web /usr/share/nginx/html

EXPOSE 80
