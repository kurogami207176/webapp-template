import os
from datetime import datetime, timezone

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health():
    """Health check — required by ECS target-group health checks."""
    return jsonify(
        status="ok",
        timestamp=datetime.now(timezone.utc).isoformat(),
        environment=os.getenv("ENVIRONMENT", "development"),
    )


@app.get("/")
def index():
    return jsonify(message="webapp-template API", version="1.0.0")


@app.errorhandler(404)
def not_found(_e):
    return jsonify(error="Not found"), 404


@app.errorhandler(500)
def internal_error(_e):
    return jsonify(error="Internal server error"), 500
