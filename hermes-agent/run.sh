#!/usr/bin/with-contenv bash
# shellcheck disable=SC1091

HERMES_HOME="/data"
HERMES_CONFIG="${HERMES_HOME}/.hermes"
OPTIONS_FILE="/data/options.json"
HERMES_INSTALL="/data/hermes-agent"

log_info() { echo "[INFO] $*" >&2; }
log_warning() { echo "[WARNING] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

get_config() {
    local key="$1"
    local default="${2:-}"
    jq -r ".$key // \"$default\"" "$OPTIONS_FILE" 2>/dev/null
}

config_exists() {
    local key="$1"
    jq -e ".$key" "$OPTIONS_FILE" >/dev/null 2>&1
}

log_info "Hermes Agent starting..."

if config_exists "ha_token"; then
    HA_TOKEN="$(get_config "ha_token")"
    if [ -n "$HA_TOKEN" ]; then
        log_info "Configuring Home Assistant..."
        mkdir -p "${HERMES_CONFIG}/secrets"
        echo "{\"api_keys\":{\"homeassistant\":\"$HA_TOKEN\"}}" > "${HERMES_CONFIG}/secrets/credentials.json"
        chmod 600 "${HERMES_CONFIG}/secrets/credentials.json"
        export HASS_TOKEN="$HA_TOKEN"
        log_info "HA token configured."
    fi
fi

if config_exists "ha_url"; then
    export HASS_URL="$(get_config "ha_url")"
fi

# Create gateway.json to enable homeassistant platform
if [ -n "$HASS_TOKEN" ]; then
    mkdir -p "${HERMES_CONFIG}"
    cat > "${HERMES_CONFIG}/gateway.json" << 'EOF'
{
  "platforms": {
    "homeassistant": {
      "enabled": true,
      "token": "PLACEHOLDER"
    }
  }
}
EOF
    # Inject token from credentials (don't hardcode in gateway.json)
    python3 -c "
import json, os
creds = json.load(open('${HERMES_CONFIG}/secrets/credentials.json'))
token = creds.get('api_keys', {}).get('homeassistant', '')
gw = json.load(open('${HERMES_CONFIG}/gateway.json'))
gw['platforms']['homeassistant']['token'] = token
json.dump(gw, open('${HERMES_CONFIG}/gateway.json', 'w'))
"
    log_info "Gateway config created."
fi

LOG_LEVEL=$(get_config "log_level" "info")
UPDATE_ON_START=$(get_config "update_on_start" "false")
GIT_BRANCH=$(get_config "git_branch" "master")

if [ "$UPDATE_ON_START" = "true" ]; then
    log_info "Checking for Hermes Agent updates..."
    if [ -d "${HERMES_INSTALL}/.git" ]; then
        cd "${HERMES_INSTALL}"
        git fetch origin "$GIT_BRANCH"
        CURRENT=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse "origin/$GIT_BRANCH")
        if [ "$CURRENT" != "$REMOTE" ]; then
            log_info "Update found! Pulling latest..."
            git pull origin "$GIT_BRANCH"
            ./venv/bin/pip install -e . --quiet
            log_info "Hermes Agent updated!"
        else
            log_info "Hermes Agent already up to date."
        fi
    fi
else
    log_info "Skipping update check (update_on_start=false)"
fi

cd "${HERMES_INSTALL}"
log_info "Starting Hermes Gateway..."

exec ./venv/bin/hermes gateway run

