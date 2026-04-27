#!/bin/bash
# shellcheck disable=SC1091

HERMES_HOME="/data"
OPTIONS_FILE="/data/options.json"

log_info() { echo "[INFO] $*"; }
log_warning() { echo "[WARNING] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

get_config() {
    local key="$1"
    local default="${2:-}"
    jq -r ".$key // \\"$default\\"" "$OPTIONS_FILE" 2>/dev/null
}

config_exists() {
    local key="$1"
    jq -e ".$key" "$OPTIONS_FILE" >/dev/null 2>&1
}

log_info "Hermes Agent starting..."

if config_exists "ha_token"; then
    HA_TOKEN=$(get_config "ha_token")
    if [ -n "$HA_TOKEN" ]; then
        log_info "Configuring Home Assistant token..."
        mkdir -p "${HERMES_HOME}/.hermes/secrets"
        echo "{\\"api_keys\\":{\\"homeassistant\\":\\"$HA_TOKEN\\"}}" > "${HERMES_HOME}/.hermes/secrets/credentials.json"
        chmod 600 "${HERMES_HOME}/.hermes/secrets/credentials.json"
        log_info "HA token configured."
    fi
fi

LOG_LEVEL=$(get_config "log_level" "info")
UPDATE_ON_START=$(get_config "update_on_start" "false")
GIT_BRANCH=$(get_config "git_branch" "master")

if [ "$UPDATE_ON_START" = "true" ]; then
    log_info "Checking for Hermes Agent updates..."
    if [ -d "${HERMES_HOME}/hermes-agent/.git" ]; then
        cd "${HERMES_HOME}/hermes-agent"
        git fetch origin "$GIT_BRANCH"
        CURRENT=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse "origin/$GIT_BRANCH")
        if [ "$CURRENT" != "$REMOTE" ]; then
            log_info "Update found! Pulling latest..."
            git pull origin "$GIT_BRANCH"
            . venv/bin/activate
            pip install -e . --quiet
            log_info "Hermes Agent updated!"
        else
            log_info "Hermes Agent already up to date."
        fi
    fi
else
    log_info "Skipping update check (update_on_start=false)"
fi

cd "$HERMES_HOME"
log_info "Starting Hermes Gateway..."

exec hermes gateway \
    --host 0.0.0.0 \
    --port 8000 \
    --log-level "$LOG_LEVEL" \
    --insecure \
    --hermes-home "$HERMES_HOME"

