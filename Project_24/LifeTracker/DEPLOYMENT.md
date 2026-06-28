# Deployment Guide

This repository is prepared for a single Oracle Cloud Ubuntu VM with Docker and Docker Compose.

## What deploys

- Flutter web frontend
- Spring Boot backend
- PostgreSQL database
- Nginx reverse proxy

## Prerequisites

1. Install Docker.
2. Install Docker Compose.
3. Open ports `80` and `443` in Oracle Cloud and the VM firewall.
4. Point your domain to the VM public IP.

## Setup

1. Clone the repository on the VM.
2. Copy `deployment/.env.example` to `.env` in the repository root.
3. Fill in:
   - `POSTGRES_PASSWORD`
   - `JWT_SECRET`
   - `CORS_ALLOWED_ORIGINS`
4. Build the backend JAR locally on Fedora before pushing:
   - `cd backend && mvn -DskipTests clean package`
5. Build the Flutter web bundle locally before pushing:
   - `cd frontend && flutter build web --release --dart-define=API_BASE_URL=/api/v1`
6. Confirm these artifacts exist in the repo checkout:
   - `backend/target/*.jar`
   - `frontend/build/web/index.html`

## Start

1. On EC2, run:
   - `git pull`
   - `docker compose build`
   - `docker compose up -d`
2. Docker Compose builds the backend from the prebuilt JAR only.
3. Nginx copies the prebuilt `frontend/build/web` directory and proxies `/api/` to the backend.
4. This keeps RAM, CPU, and disk usage low for `t3.micro`.

## SSL

1. Install Certbot on the VM.
2. Issue certificates for your domain.
3. Replace the Nginx config with `deployment/nginx/https.conf.example` or merge its TLS block into `deployment/nginx/default.conf`.
4. Reload Nginx.

## Backups

- Use `deployment/backup.sh` to create a PostgreSQL dump.
- Use `deployment/restore.sh <file.sql>` to restore a dump.

## Updates

1. Build the backend JAR locally.
2. Build the Flutter web bundle locally.
3. Push the changes to GitHub.
4. On EC2, run:
   - `git pull`
   - `docker compose build`
   - `docker compose up -d`
5. Or use `deployment/update.sh` after the new artifacts are present.

## Health Checks

- The backend exposes `/actuator/health`.
- Compose includes a backend health check.
- Use `deployment/healthcheck.sh` for a quick status check.
