#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

docker compose --env-file "${ENV_FILE}" ps
docker compose --env-file "${ENV_FILE}" exec -T backend curl -fsS http://localhost:8080/actuator/health
