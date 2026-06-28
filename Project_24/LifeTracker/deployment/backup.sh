#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
BACKUP_DIR="${ROOT_DIR}/deployment/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/lifetracker_${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

docker compose --env-file "${ENV_FILE}" exec -T postgres sh -lc 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "${BACKUP_FILE}"

echo "Backup created at ${BACKUP_FILE}"
