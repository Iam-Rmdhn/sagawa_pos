#!/usr/bin/env bash
set -euo pipefail

# Ensure Go binary is in PATH when running via sudo
export PATH="/usr/local/go/bin:${PATH}"

SERVICE="sagawa-pos"
APP_DIR="/var/www/sagawa-pos/sagawa_pos/backend"
BINARY_NAME="sagawa-pos-api"
LOG_DIR="/var/log/sagawa-pos"

log() { echo "[$(date +'%F %T')] $*"; }

if [[ $EUID -ne 0 ]]; then
  log "Please run as root (sudo)." >&2
  exit 1
fi

log "Ensuring log directory exists..."
mkdir -p "$LOG_DIR"

log "Switching to app directory: $APP_DIR"
cd "$APP_DIR"

if [[ -d .git ]]; then
  log "Pulling latest code..."
  git pull --ff-only
else
  log "Skipped git pull (no .git in $APP_DIR)."
fi

log "Stopping service $SERVICE (if running)..."
systemctl stop "$SERVICE" || true

log "Building Go binary..."
go build -o "$APP_DIR/$BINARY_NAME" main.go
chmod +x "$APP_DIR/$BINARY_NAME"

log "Reloading systemd units..."
systemctl daemon-reload

log "Starting service $SERVICE..."
systemctl start "$SERVICE"

log "Service status:"
systemctl status --no-pager --lines 20 "$SERVICE"

log "Done."