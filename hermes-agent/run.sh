#!/usr/bin/with-contenv bash
# shellcheck disable=SC1091

HERMES_HOME="/data"
HERMES_CONFIG="${HERMES_HOME}/.hermes"
OPTIONS_FILE="/data/options.json"
HERMES_INSTALL="/opt/hermes-agent"

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

# Configure Home Assistant credentials
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
    # Inject token from credentials
    python3 -c "
import json
creds = json.load(open('${HERMES_CONFIG}/secrets/credentials.json'))
token = creds.get('api_keys', {}).get('homeassistant', '')
gw = json.load(open('${HERMES_CONFIG}/gateway.json'))
gw['platforms']['homeassistant']['token'] = token
json.dump(gw, open('${HERMES_CONFIG}/gateway.json', 'w'))
"
    log_info "Gateway config created."
fi

cd "${HERMES_INSTALL}"
log_info "Starting Hermes Gateway..."

exec ./venv/bin/hermes gateway run
