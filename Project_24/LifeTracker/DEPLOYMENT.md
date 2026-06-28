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
   - `API_BASE_URL`

## Start

1. Run `docker compose up -d --build`.
2. The backend starts with the `prod` profile.
3. Nginx serves the Flutter web app and proxies `/api/` to the backend.

## SSL

1. Install Certbot on the VM.
2. Issue certificates for your domain.
3. Replace the Nginx config with `deployment/nginx/https.conf.example` or merge its TLS block into `deployment/nginx/default.conf`.
4. Reload Nginx.

## Backups

- Use `deployment/backup.sh` to create a PostgreSQL dump.
- Use `deployment/restore.sh <file.sql>` to restore a dump.

## Updates

1. Pull the latest repository changes.
2. Refresh `.env` only if required.
3. Run `deployment/update.sh`.

## Health Checks

- The backend exposes `/actuator/health`.
- Compose includes a backend health check.
- Use `deployment/healthcheck.sh` for a quick status check.
