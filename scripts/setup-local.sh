#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

log() { echo "[setup] $*"; }
error() { echo "[setup] ERROR: $*" >&2; exit 1; }

# Check Python
python3 --version &>/dev/null || error "Python 3 not found"
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
[[ "$PYTHON_MINOR" -ge 12 ]] || error "Python 3.12+ required"

# Check Docker
docker info &>/dev/null || error "Docker is not running"

# Copy .env
if [[ ! -f "$ROOT_DIR/.env" ]]; then
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  log "Created .env from .env.example — update JWT_SECRET before proceeding"
fi

# Set up Python venv
if [[ ! -d "$ROOT_DIR/api/.venv" ]]; then
  log "Creating Python virtual environment..."
  python3 -m venv "$ROOT_DIR/api/.venv"
fi

log "Installing Python dependencies..."
"$ROOT_DIR/api/.venv/bin/pip" install --upgrade pip --quiet
"$ROOT_DIR/api/.venv/bin/pip" install -r "$ROOT_DIR/api/requirements-dev.txt" --quiet

# Install Node deps for web
log "Installing Node.js dependencies..."
cd "$ROOT_DIR/web" && npm install --silent

# Start local DynamoDB + create tables
log "Starting local DynamoDB..."
docker compose -f "$ROOT_DIR/docker/docker-compose.yml" up -d dynamodb dynamodb-setup

log "Waiting for DynamoDB setup to complete..."
until docker compose -f "$ROOT_DIR/docker/docker-compose.yml" ps dynamodb-setup | grep -q "exited\|completed"; do
  sleep 1
done

log ""
log "Setup complete!"
log "  Start all services:  docker compose -f docker/docker-compose.yml up"
log "  Run API tests:       cd api && source .venv/bin/activate && pytest"
log "  API docs:            http://localhost:8000/docs"
