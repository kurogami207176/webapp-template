#!/usr/bin/env bash
set -euo pipefail

# Runs Alembic migrations locally or against a target DATABASE_URL
# Usage: ./scripts/db-migrate.sh [upgrade|downgrade] [revision]

COMMAND="${1:-upgrade}"
REVISION="${2:-head}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR/api"

if [[ -f ".venv/bin/activate" ]]; then
  source .venv/bin/activate
fi

echo "Running: alembic $COMMAND $REVISION"
alembic "$COMMAND" "$REVISION"
echo "Done."
