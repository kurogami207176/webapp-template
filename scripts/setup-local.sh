#!/usr/bin/env bash
set -euo pipefail

REQUIRED_NODE_MAJOR=20
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

log() { echo "[setup] $*"; }
error() { echo "[setup] ERROR: $*" >&2; exit 1; }

# Check Node version
CURRENT_NODE=$(node --version | grep -oE '[0-9]+' | head -1)
if [[ "$CURRENT_NODE" -lt "$REQUIRED_NODE_MAJOR" ]]; then
  error "Node.js $REQUIRED_NODE_MAJOR+ required (found $CURRENT_NODE). Use nvm: nvm use"
fi
log "Node.js version OK ($CURRENT_NODE)"

# Copy .env if not present
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  log "Created .env from .env.example — update the values before proceeding"
fi

# Install dependencies
log "Installing dependencies..."
cd "$ROOT_DIR"
npm install

# Start postgres
log "Starting database..."
docker compose -f docker/docker-compose.yml up -d db

# Wait for DB to be healthy
log "Waiting for database to be ready..."
until docker compose -f docker/docker-compose.yml exec db pg_isready -U postgres &>/dev/null; do
  sleep 1
done
log "Database is ready"

# Run migrations
log "Running database migrations..."
npm run db:migrate

# Optional: seed
if [[ "${SEED:-true}" == "true" ]]; then
  log "Seeding database..."
  npm run db:seed
fi

log ""
log "Setup complete!"
log "  Start dev servers:  npm run dev"
log "  Run tests:          npm test"
log "  API docs:           http://localhost:3000/health"
