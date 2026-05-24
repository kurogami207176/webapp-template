import logging
import os
from datetime import datetime, timezone

from flask import Flask, jsonify

from db import get_pool

logger = logging.getLogger(__name__)

app = Flask(__name__)


# ---------------------------------------------------------------------------
# Infrastructure / health
# ---------------------------------------------------------------------------

@app.get("/health")
def health():
    """
    Health check — called by ECS Express / ALB every 15 s.

    Returns 200 as long as the process is alive. Database connectivity is
    checked separately (/health/db) so a DB blip never kills the service.
    """
    return jsonify(
        status="ok",
        timestamp=datetime.now(timezone.utc).isoformat(),
        environment=os.getenv("ENVIRONMENT", "development"),
    )


@app.get("/health/db")
def health_db():
    """
    Deep health check — verifies the database is reachable.
    Returns 503 if the pool is not configured or the query fails.
    """
    pool = get_pool()
    if pool is None:
        return jsonify(status="unconfigured", detail="DB_SECRET_ARN not set"), 503

    try:
        with pool.connection() as conn:
            conn.execute("SELECT 1")
        return jsonify(status="ok")
    except Exception as exc:
        logger.exception("DB health check failed")
        return jsonify(status="error", detail=str(exc)), 503


# ---------------------------------------------------------------------------
# Application routes
# ---------------------------------------------------------------------------

@app.get("/")
def index():
    return jsonify(message="webapp-template API", version="1.0.0")


@app.get("/hello")
def hello():
    return jsonify(message="Hello, world!")


# ---------------------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------------------

@app.errorhandler(404)
def not_found(_e):
    return jsonify(error="Not found"), 404


@app.errorhandler(500)
def internal_error(_e):
    return jsonify(error="Internal server error"), 500
