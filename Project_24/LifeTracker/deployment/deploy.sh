#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing .env file at ${ENV_FILE}."
  echo "Copy deployment/.env.example to .env and fill in the values first."
  exit 1
fi

docker compose --env-file "${ENV_FILE}" up -d --build
