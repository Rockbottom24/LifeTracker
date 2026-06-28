#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ROOT_DIR}/frontend/build/web/index.html" ]]; then
  echo "Missing prebuilt Flutter web output at frontend/build/web."
  echo "Build it outside Docker first, for example:"
  echo "  cd frontend && flutter build web --release --dart-define=API_BASE_URL=/api/v1"
  exit 1
fi

docker compose --env-file "${ENV_FILE}" pull
docker compose --env-file "${ENV_FILE}" up -d --build
