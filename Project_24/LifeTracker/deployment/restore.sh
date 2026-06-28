#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
BACKUP_FILE="${1:-}"

if [[ -z "${BACKUP_FILE}" ]]; then
  echo "Usage: restore.sh path/to/backup.sql"
  exit 1
fi

docker compose --env-file "${ENV_FILE}" exec -T postgres sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < "${BACKUP_FILE}"
