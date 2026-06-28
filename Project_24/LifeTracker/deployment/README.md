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

- Build the backend JAR locally with `cd backend && mvn -DskipTests clean package`.
- Build the Flutter web bundle locally with `cd frontend && flutter build web --release --dart-define=API_BASE_URL=/api/v1`.
- The generated backend JAR must exist under `backend/target/` before Docker Compose runs.
- The generated Flutter web bundle must exist under `frontend/build/web/` before Docker Compose runs.
- The server does not install Maven, Flutter, or run any build tooling inside Docker.
- On EC2, the deployment flow is:
  - `git pull`
  - `docker compose build`
  - `docker compose up -d`
- The backend runs with `SPRING_PROFILES_ACTIVE=prod`.
- Secrets must live in `.env` and never in the repository.
- HTTPS is prepared via `deployment/nginx/https.conf.example` for Let's Encrypt.
