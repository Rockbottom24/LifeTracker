# Deployment Assets

This folder contains the production helpers for LifeTracker.

## Files

- `.env.example`: sample environment variables for Docker Compose
- `deploy.sh`: builds images and starts the stack
- `update.sh`: rebuilds and redeploys the stack
- `backup.sh`: creates a PostgreSQL backup
- `restore.sh`: restores a PostgreSQL backup
- `healthcheck.sh`: checks backend and frontend health
- `nginx/`: Nginx reverse-proxy and web-build files

## Notes

- The frontend web app is built inside the Nginx image.
- The backend runs with `SPRING_PROFILES_ACTIVE=prod`.
- Secrets must live in `.env` and never in the repository.
- HTTPS is prepared via `deployment/nginx/https.conf.example` for Let's Encrypt.
