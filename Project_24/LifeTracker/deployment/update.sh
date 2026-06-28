#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

docker compose --env-file "${ENV_FILE}" pull
docker compose --env-file "${ENV_FILE}" up -d --build
